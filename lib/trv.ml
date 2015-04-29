open Core.Std
open Async.Std

let command =
  Command.group ~summary:"Base tooling system for Afiniate projects"
  [Build.desc;
   Olib.desc]

let () =
  Command.run ~version:"1.0" ~build_info:"" command
