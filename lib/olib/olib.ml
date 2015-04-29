open Core.Std
open Async.Std

let name = "opam"

let command =
  Command.group ~summary:"opam specific tooling for the system"
    [Olib_make_opam.desc;
     Olib_prepare.desc]

let desc = (name, command)
