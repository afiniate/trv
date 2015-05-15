open Core.Std
open Async.Std

module Log = Log_common
module Cmd = Cmd_common
module Flib = Flib_common
module Dir = Flib_dir
module Build = Build

let command =
  Command.group ~summary:"Base tooling system for Afiniate projects"
  [Build.desc;
   Opam.desc]

let () =
  Command.run ~version:"1.0" ~build_info:"" command
