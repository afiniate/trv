trv
===

This serves as a shim for `vrt`. It extracts the minimal commands we
need in order to bootstrap a system. For more information, refer to
the [vrt repo](https://github.com/afiniate/vrt).


### Building the opam package

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
