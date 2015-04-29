open Core.Std
open Async.Std

let name = "prj"

let command =
  Command.group ~summary:"Project tooling for bootstrapping projects"
    [Prj_make_META.desc;
     Prj_semver.desc;
     Prj_make_dot_merlin.desc;
     Prj_gen_mk.desc]

let desc = (name, command)
