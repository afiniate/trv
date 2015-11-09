open Core.Std
open Core_extended.Std
open Async.Std
open Deferred.Monad_infix

exception Execution_failed of Error.t

type shell_desc = { prog: String.t;
                    args: String.t List.t } with sexp

let guard fn =
  Monitor.try_with
    fn
  >>| function
  | Ok _ ->
    shutdown 0
  | Error monitor_exn ->
    (match Monitor.extract_exn monitor_exn with
     | Async_shell.Process.Failed result ->
       if not (result.stdout = "")
       then print_string result.stdout
       else ();
       if not (result.stderr = "")
       then print_string result.stderr
       else ()
     | new_exn ->
       raise new_exn);
    shutdown 1

let result_guard def_fn =
  guard (fun () ->
      def_fn ()
      >>= function
      | Ok _ ->
        return ()
      | Error exn ->
        raise exn)

let get_cwd
  : String.t Option.t -> String.t Deferred.t =
  function
  | Some cwd -> return cwd
  | None -> Sys.getcwd ()

let sh
  : ?working_dir:String.t -> ?shell:shell_desc -> String.t ->
    (String.t, Exn.t) Deferred.Result.t =
  fun ?working_dir ?(shell = {prog="bash"; args=["-c"]}) cmd ->
    get_cwd working_dir
    >>= fun cwd ->
    let actual_args = List.concat [shell.args; [cmd]] in
    Process.run ~working_dir:cwd ~prog:shell.prog ~args:actual_args ()
    >>= function
    | Ok result -> 
      return @@ Ok result
    | Error err ->
      return @@ Error (Execution_failed err)

let sh_one
  : ?working_dir:String.t -> ?shell:shell_desc -> String.t ->
    (String.t, Exn.t) Deferred.Result.t =
  fun ?working_dir ?shell cmd ->
    let split result = String.split ~on:'\n' result
                       |> function 
                       | h::_ -> return @@ Ok h
                       | [] -> return @@ Ok "" in

    let open Deferred.Result.Monad_infix in
    sh ?working_dir ?shell cmd
    >>= split

let simply_print_response 
  : ?working_dir:String.t -> ?shell:shell_desc -> String.t ->
    (Unit.t, Exn.t) Deferred.Result.t =
  fun ?working_dir ?shell cmd ->
    sh ?working_dir ?shell cmd
    >>= function
    | Ok result -> 
      print_string result;
      return @@ Ok ()
    | Error (Execution_failed err) -> 
      print_string @@ Error.to_string_hum err;
      return @@ Error (Execution_failed err)
    | Error err -> 
      print_string @@  Exn.to_string_hum err;
      return @@ Error err


let cmd_simply_print_response ~name ~desc ?working_dir ?shell cmd =
  let command =
    Command.async_basic ~summary:desc
      Command.Spec.empty
      (fun () -> 
         result_guard 
           (fun () -> simply_print_response ?working_dir ?shell cmd )) in
  (name, command)
