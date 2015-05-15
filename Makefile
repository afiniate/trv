NAME:=trv
LICENSE:="OSI Approved :: Apache Software License v2.0"
AUTHOR:="Afiniate, Inc."
ORGANIZATION:="afiniate"
HOMEPAGE:="https://github.com/afiniate/trv"

DEV_REPO:="git@github.com:afiniate/trv.git"
BUG_REPORTS:="https://github.com/afiniate/trv/issues"

BUILD_DEPS:=core async async_unix async_extra sexplib.syntax sexplib \
	async_shell core_extended async_find cohttp.async uri
DEPS:=$(BUILD_DEPS)

DESC_FILE := $(CURDIR)/descr

BUILD_DIR := $(CURDIR)/_build
SOURCE_DIR := lib
LIB_DIR := $(BUILD_DIR)/$(SOURCE_DIR)
MLIS:=$(foreach f,$(wildcard $(LIB_DIR)/*.mli),$(notdir $f))
TRV := $(LIB_DIR)/trv.native
SEMVER = $(shell $(TRV) build semver)

EXTRA_TARGETS := trv.native

PREFIX := $(shell dirname $$(dirname $$(which ocamlfind)))

### Knobs
PARALLEL_JOBS ?= 2
BUILD_FLAGS ?= -use-ocamlfind -cflags -bin-annot -lflags -g

# =============================================================================
# Useful Vars
# =============================================================================

BUILD := ocamlbuild -j $(PARALLEL_JOBS) -build-dir $(BUILD_DIR) $(BUILD_FLAGS)

MOD_DEPS=$(foreach DEP,$(DEPS), --depends $(DEP))
BUILD_MOD_DEPS=$(foreach DEP,$(BUILD_DEPS), --build-depends $(DEP))

UTOP_MODS=$(foreach DEP,$(DEPS),\#require \"$(DEP)\";;)

UTOP_INIT=$(BUILD_DIR)/init.ml

### Test bits
TESTS_DIR := $(BUILD_DIR)/tests
TEST_RUN_SRCS := $(shell find $(SOURCE_DIR) -name "*_tests_run.ml")
TEST_RUN_EXES := $(notdir $(TEST_RUN_SRCS:%.ml=%))
TEST_RUN_CMDS := $(addprefix $(TESTS_DIR)/, $(TEST_RUN_EXES))
TEST_RUN_TARGETS:= $(addprefix run-, $(TEST_RUN_EXES))

# =============================================================================
# Rules to build the system
# =============================================================================

.PHONY: all build rebuild metadata install unit-test integ-test test $(TEST_RUN_CMDS)

.PRECIOUS: %/.d

%/.d:
	mkdir -p $(@D)
	touch $@

all: build

rebuild: clean all

build:
	$(BUILD) $(NAME).cma $(NAME).cmx $(NAME).cmxa $(NAME).a $(NAME).cmxs \$(EXTRA_TARGETS)

metadata: build
	$(TRV) build make-meta --name $(NAME) --target-dir $(LIB_DIR) \
	--root-file Makefile --semver $(SEMVER) --description-file \
	'$(DESC_FILE)' $(MOD_DEPS)

# This is only used to help during local opam package
# development
opam: build
	$(TRV) opam make-opam --target-dir $(CURDIR) --name $(NAME) \
	--semver $(SEMVER) --homepage $(HOMEPAGE) --dev-repo $(DEV_REPO) \
	--lib-dir $(LIB_DIR) --license $(LICENSE) --author $(AUTHOR) \
	--maintainer $(AUTHOR) --bug-reports $(BUG_REPORTS) \
	--build-cmd "make" --install-cmd 'make "install" "PREFIX=%{prefix}%" \
	"SEMVER=%{aws_async:version}%"' --remove-cmd 'make "remove" \
	"PREFIX=%{prefix}%"' $(BUILD_MOD_DEPS) $(MOD_DEPS)

unpin-repo:
	opam pin remove -y $(NAME)

pin-repo:
	opam pin add -y $(NAME) $(CURDIR)

install-local-opam: opam pin-repo
	opam remove $(NAME); opam install $(NAME)

prepare: build
	$(TRV) opam prepare --organization $(ORGANIZATION) \
	--target-dir $(BUILD_DIR) --homepage $(HOMEPAGE) \
	--dev-repo $(DEV_REPO) --lib-dir $(LIB_DIR) --license $(LICENSE) \
	--name $(NAME) --author $(AUTHOR) --maintainer $(AUTHOR) \
	--bug-reports $(BUG_REPORTS) --build-cmd "make" \
	--install-cmd 'make "install" "PREFIX=%{prefix}%"' \
	--remove-cmd 'make "remove" "PREFIX=%{prefix}%"' $(BUILD_MOD_DEPS) \
	$(MOD_DEPS) --description-file '$(DESC_FILE)'

install-extra: build
	cp $(BUILD_DIR)/lib/trv.native $(PREFIX)/bin/trv

install-library: metadata
	cd $(LIB_DIR); ocamlfind install $(NAME) META `find ./  -name "*.cmi" \
	-o -name "*.cmo" -o -name "*.o" -o -name "*.cmx" -o -name "*.cmxa" \
	-o -name "*.cmxs" -o -name "*.a" -o -name "*.cma"`

install: install-library install-extra

submit: prepare
	opam-publish submit $(BUILD_DIR)/$(NAME).$(SEMVER)

remove:
	ocamlfind remove $(NAME)

clean:
	rm -rf $(CLEAN_TARGETS)
	rm -rf $(BUILD_DIR)

# =============================================================================
# Rules for testing
# =============================================================================

compile-tests: $(TEST_RUN_CMDS)

$(TEST_RUN_CMDS): $(TESTS_DIR)/.d
	$(BUILD) $(notdir $@).byte
	@find $(LIB_DIR) -name $(notdir $@).byte -exec cp {} $(@) \;

$(TEST_RUN_TARGETS): run-%: $(TESTS_DIR)/%
	$<

test: build unit-test integ-test

unit-test: $(filter %_unit_tests_run, $(TEST_RUN_TARGETS))

integ-test: $(filter %_integ_tests_run, $(TEST_RUN_TARGETS))

# =============================================================================
# Support
# =============================================================================
$(UTOP_INIT): build
	@echo "$(UTOP_MODS)" > $(UTOP_INIT)
	@echo "open Core.Std;;" >> $(UTOP_INIT)
	@echo "open Async.Std;;" >> $(UTOP_INIT)
	@echo '#load "$(NAME).cma";;' >> $(UTOP_INIT)

utop: $(UTOP_INIT)
	utop -I $(LIB_DIR) -init $(UTOP_INIT)

.merlin: build
	$(TRV) build make-dot-merlin \
		--build-dir $(BUILD_DIR) \
		--lib "$(DEPS)" \
		--source-dir $(SOURCE_DIR)
