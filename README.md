trv
===

This serves as a shim for `vrt`. It extracts the minimal commands we
need in order to bootstrap a system. For more information, refer to
the [vrt repo](https://github.com/afiniate/vrt).


### Building trv with nix

In our experience nix is the most reliable way of handling dependencies by
far. Even if you are not familiar with nix, the recommended way of building trv
is letting nix handle the dependencies. We host [our own branch of
nixpkgs](https://github.com/afiniate/nixpkgs) while TRV is not ready to be pull
requested in the official nixpkgs repository. However, as nix works, you don't
need to worry about this, it doesn't mean that you need to mess with your
environment if you have nix already installed.

#### Installing nixpkgs

If you don't have nixpkgs installed, you should follow [these
steps](http://nixos.org/nix/manual/#chap-installation) (the easiest is to just
run the installing script).

After you are done, nix will be installed in `/nix` and should have created a
few `.nix*` files in your home. That is all; if you want to remove nix you just
need to remove `/nix` and everything inside it.

To verify everything is working you could run `~/.nix-profile/bin/nix-env -i
firefox`, if everything is ok, after a while (nix tries to be as pure as
possible, so it won't use anything in your environment and download hashed
copies of all dependencies instead) you should have a working firefox installed
in `~/.nix-profile/bin/firefox`.

Nix installs everything in the Nix store (`/nix/store`) but for convenience you
can "install" things in your profile (`$HOME/.nix-profile`) by linking them
there, so it is useful to add `~/.nix-profile/bin` to your `PATH`. Only the
things you install with `nix-env -i` will be available there. If you want to
remove something from your profile, e.g. firefox, run `nix-env -e firefox`. Note
that removing things from your profile doesn't remove them from the store. If
you want to know more on how to manage the Nix store and your profile, refer to
Nix's documentation. This is enough to just get trv installed in your profile.

#### Installing trv

Now you need to clone our fork of nixpkgs (again, this will not change anything
in your official nix installation, so don't worry about it). Just run this in
any directory you like:

    git clone git@github.com:afiniate/nixpkgs.git

And finally run

    ~/.nix-profile/bin/nix-env -i trv -f /path/to/afiniate/nixpkgs/default.nix

The first time you run this it will take some time, once it is finished you
should have a working trv in `~/.nix-profile/bin`

#### Modifying and compiling trv

If you want to modify and compile trv, instead of running

    ~/.nix-profile/bin/nix-env -i trv -f /path/to/afiniate/nixpkgs/default.nix

do

    ~/.nix-profile/bin/nix-shell --pure -A trv /path/to/afiniate/nixpkgs/default.nix

That will drop you in a shell with everything that you need to compile trv (but
only with that, so use a different shell for editing, git, etc).

### Building the opam package

The opam method is less reliable than the nix method, so it is not
recommmended. However if you really want to make an opam package, follow this
instructions

The easiest way to build and test the opam package is to pin the local
repository to opam. Follow the instructions is the
[Opam Pin part of the Opam Packaging docs](http://opam.ocaml.org/doc/Packaging.html).

Once pinned you can install the package as if it where a remote opam
package and everything should just work. The model goes as.

    $> make opam
    $> opam pin add trv . -n
    $> opam install trv

That will build and install the system. There can, at times, be
problems if you don't do the `make opam` before the opam pin. Also you
must do `opam remove trv` before reinstalling.
