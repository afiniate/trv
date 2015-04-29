open Core.Std
open Async.Std

let name = "build"

let command =
  Command.group ~summary:"Project tooling for bootstrapping projects"
    [Build_make_META.desc;
     Build_semver.desc;
     Build_make_dot_merlin.desc;
     Build_gen_mk.desc]

let desc = (name, command)
