open Core.Std
open Async.Std

exception Execution_failed of Error.t

type shell_desc = { prog: String.t;
                    args: String.t List.t } with sexp

val sh
  : ?working_dir:String.t -> ?shell:shell_desc -> String.t -> (String.t, Exn.t) Deferred.Result.t 
(** Run the program with the args specified. Optionally provide as shell
    argument. The shell argument is a list of commands and arguments. 
    For example the default argument value for `shell` is ["bash"; "-c"] *)

val sh_one
  : ?working_dir:String.t -> ?shell:shell_desc -> String.t -> (String.t, Exn.t) Deferred.Result.t 
(* Run the specified command with the specified arguments as in `sh`. Returning
   only the first line of results *)

val simply_print_response
  : ?working_dir:String.t -> ?shell:shell_desc -> String.t ->
  (Unit.t, Exn.t) Deferred.Result.t 
(** Run the command and return the result as a deferred, or the
    exn result *)

val cmd_simply_print_response
  : name:String.t ->
  desc:String.t ->
  ?working_dir:String.t -> ?shell:shell_desc -> String.t ->
  String.t * Command.t
(** This provides a complete command that only runs the shell command
    and prints the result to stdio *)

val result_guard: (Unit.t -> ('a, Exn.t) Deferred.Result.t) -> Unit.t Deferred.t
(** We tend to use Deferred.Result.t. However, the command infrastructure
    requires a deferred. This provides an automatic translation. It also
    Handles monitoring with `guard` as below  *)

val guard: (Unit.t -> 'a Deferred.t) -> Unit.t Deferred.t
(** This provides a guard that can be used to return proper exit
    values to the Async command system. It also does a decent job of
    printing out common error messages *)
