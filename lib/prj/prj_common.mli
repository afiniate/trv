open Core.Std
open Async.Std

(** Provide a useful functions for Async.Command interaction *)

val search_dominating_file: base_dir:String.t -> dominating:String.t ->
  Unit.t -> String.t Option.t Deferred.t
(** Given a base directory and a dominating file this command
    searches up through * the directory structure looking for the
    dominating file *)

val simply_print_response:
  exn:Exn.t ->
  (String.t Option.t Async_kernel.Deferred.t, Unit.t, String.t,
   String.t Option.t Async.Std.Deferred.t) format4 ->
  (Unit.t, Exn.t) Deferred.Result.t
(** Simply run the command and return the result as a deferred, or the
    exn result *)

val cmd_simply_print_response:
  name:String.t ->
  desc:String.t ->
  exn:Exn.t ->
  (String.t Option.t Async_kernel.Deferred.t, Unit.t, String.t,
   String.t Option.t Async.Std.Deferred.t) format4 ->
  String.t * Command.t
(** This provides a complete command that only runs the shell command
    and prints the result. *)

val result_guard: (Unit.t -> ('a, Exn.t) Deferred.Result.t) -> Unit.t Deferred.t
(** In the voteraise system its much more common to use
    Deferred.Result.t. However, the command infrastructure requires a
    deferred. This provides an automatic translation. It also Handles
    monitoring with `guard` as below *)

val guard: (Unit.t -> 'a Deferred.t) -> Unit.t Deferred.t
(** This provides a guard that can be used to return proper exit
    values to the Async command system. It also does a decent job of
    printing out common error messages *)


val dump: dir:String.t -> name:String.t -> contents:String.t
  -> (Unit.t, Exn.t) Deferred.Result.t
(** Writes a file with in the indicated path with the given name all at once *)

val log_level: Log.Level.t Command.Spec.Arg_type.t
(** A command arg that can be used as part of a command spec *)

val flag: Log.Level.t Command.Spec.param
(** A Command.Spec param that can be used in a Command spec. It binds
    `-l` and `--log-level` to a var `log_level` *)

val create: Log.Level.t -> Log.t
(** Create a logger to std out *)

val flush: Log.t -> (Unit.t, Exn.t) Deferred.Result.t
(** A helper function to help log flushing fit into Deferred.Result *)
