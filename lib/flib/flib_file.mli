open Core.Std
open Async.Std

(** Provide a useful functions for Async.Command interaction *)

val search_dominating_file: base_dir:String.t -> dominating:String.t ->
  Unit.t -> String.t Option.t Deferred.t
(** Given a base directory and a dominating file this command
    searches up through * the directory structure looking for the
    dominating file *)

val dump: dir:String.t -> name:String.t -> contents:String.t
  -> (Unit.t, Exn.t) Deferred.Result.t
(** Writes a file with in the indicated path with the given name all at once *)


