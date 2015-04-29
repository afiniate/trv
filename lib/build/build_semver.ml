open Core.Std
open Async.Std
open Re2.Std

exception Semver_commit_count_failure of String.t
exception Semver_version_parse_failure of String.t
exception Semver_git_describe_parse_failure of String.t

let create_with_commit_count ref =
  Async_shell.sh_one
    "git rev-list HEAD --count"
  >>| function
  | Some count ->
    Ok ("0.0.0" ^ "+build." ^ count ^ "." ^ ref)
  | None ->
    Error (Semver_commit_count_failure"nothing")

let deep_parse potential_ver =
  return (let open Or_error.Monad_infix in
          Re2.create "^((v)?(\\d+(\\.\\d+(\\.\\d+)?)))$|^([A-Fa-f0-9]+)$"
          >>= fun re ->
          Re2.find_submatches re potential_ver)

let parse_ver potential_ver top =
  deep_parse potential_ver
  >>= function
  | Ok [|Some _; _; _; _; _; _; Some ref|] ->
    if top
    then create_with_commit_count ref
    else return @@ Ok ref

  | Ok [|Some _; _; _; Some ver; _; _; _|] ->
    return @@ Ok ver
  | _ ->
    return @@ Error (Semver_version_parse_failure potential_ver)

let split_version = function
  | Some ver ->
    return (let open Or_error.Monad_infix in
            Re2.create "-"
            >>| fun re ->
            Re2.split re ver)
  | _ ->
    return @@ Or_error.error_string "No version returned"

let parse ver =
  split_version ver
  >>= function
  | Ok [ver] ->
    parse_ver ver true
  | Ok [ver; count; gitref] ->
    parse_ver ver false
    >>|? fun ver ->
    ver ^ "+build." ^ count ^ "." ^ gitref
  | _ ->
    (match ver with
     | Some ver ->
       return @@ Error (Semver_git_describe_parse_failure ver)
     | None ->
       return @@ Error (Semver_git_describe_parse_failure "none"))

let get_semver () =
  Async_shell.sh_one "git describe --tags --always"
  >>= fun str_opt ->
  parse str_opt

let do_semver () =
  get_semver ()
  >>|? fun result ->
  print_string result;
  Ok ()

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

let spec =
  let open Command.Spec in
  empty

let name = "semver"

let command =
  Command.async_basic ~summary:"Parse git repo information into a semantic version"
    spec
    (fun () ->
       result_guard (fun _ -> do_semver ()))

let desc = (name, command)
