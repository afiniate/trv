#!/bin/bash

set -e

ROOT=$1
TRV="$ROOT/_build/lib/trv.byte"

cat <<EOF

opam-version: "1.2"
name: "trv"
version: "`$TRV build semver`"
maintainer: "contact@afiniate.com"
author: "contact@afiniate.com"
homepage: "https://github.com/afiniate/trv"
bug-reports: "https://github.com/afiniate/trv/issues"
license: "Apache v2"
dev-repo: "git@github.com:afiniate/trv"

available: [ ocaml-version >= "4.02" ]

build: [
  [make "build"]
]
install: [make "install" "PREFIX=%{prefix}%"]
remove: [make "remove" "PREFIX=%{prefix}%"]
depends: ["ocamlfind" "core" "async" "async_shell" "async_unix" "async_extra"
          "sexplib" "async_shell" "core_extended" "async_find" "cohttp.async"
          "uri"]

EOF
