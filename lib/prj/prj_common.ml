open Core.Std
open Core_extended.Std
open Async.Std
open Deferred.Monad_infix

let rec search_dominating_file' dominating = function
  | [] ->
    return None
  | h::t ->
    let path = Filename.implode @@ List.rev (dominating::t) in
    Sys.file_exists path
    >>= (function
        | `Yes -> return @@ Some (Filename.implode @@ List.rev t)
        | `No -> search_dominating_file' dominating t
        | `Unknown -> search_dominating_file' dominating t)

let search_dominating_file ~base_dir ~dominating () =
  let element_list = List.rev @@ Filename.explode base_dir in
  search_dominating_file' dominating element_list

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

let simply_print_response ~exn format =
  (Async_shell.sh_one format)
  >>= function
  | Some result ->
    print_string result;
    return @@ Ok ()
  | None ->
    return @@ Error exn

let cmd_monitor ~exn format () =
  result_guard (fun _ -> simply_print_response ~exn format)

let cmd_simply_print_response ~name ~desc ~exn format =
  let command =
    Command.async_basic ~summary:desc
      Command.Spec.empty
      (cmd_monitor ~exn format) in
  (name, command)

let dump
  : dir:String.t -> name:String.t -> contents:String.t
  -> (Unit.t, Exn.t) Deferred.Result.t =
  fun ~dir ~name ~contents ->
    let path = Filename.implode [dir; name] in
    try
      Writer.save path ~contents
      >>| fun _ ->
      Ok ()
    with exn ->
      return @@ Error exn

let log_level =
  Command.Spec.Arg_type.create
    (function
      | "v" -> `Error
      | "vv" -> `Info
      | "vvv" -> `Debug
      | "error" -> `Error
      | "info" -> `Info
      | "debug" -> `Debug
      | _ -> `Debug)

let flag =
  Command.Spec.(flag ~aliases:["-l"] "--log-level" (optional_with_default `Info log_level)
                  ~doc:"log-level The log level to set")

let create log_level =
  Log.create log_level [Log.Output.stdout ()]

let flush logger =
  Log.flushed logger
  >>| fun _ ->
  Ok ()
