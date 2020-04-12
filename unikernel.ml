open Lwt.Infix

let error_handler ?request:_ error start_response =
  let open Httpaf in
  let response_body = start_response Headers.empty in
  ( match error with
  | `Exn exn ->
      Body.write_string response_body (Printexc.to_string exn) ;
      Body.write_string response_body "\n"
  | #Status.standard as error ->
      Body.write_string response_body (Status.default_reason_phrase error) ) ;
  Body.close_writer response_body

let request_handler reqd =
  let open Httpaf in
  let message = "hello world" in
  let headers = Headers.of_list ["content-length", Int.to_string (String.length message)] in
  let req_body = Reqd.request_body reqd in
  Body.close_reader req_body;
  Reqd.respond_with_string reqd (Response.create ~headers `OK) message

module Server
    (C : Mirage_console.S)
    (T : Mirage_time.S)
    (PClock : Mirage_clock.PCLOCK)
    (StackV4 : Mirage_stack.V4) =
struct
  module Paf = Paf.Make (T) (StackV4)
  module Logs_reporter = Mirage_logs.Make (PClock)

  let start _console _time _pclock stack =
    Logs.(set_level (Some Debug)) ;
    Logs_reporter.(create () |> run)
    @@ fun () ->
    let port = Key_gen.port () in
    Logs.info (fun m ->
        m "Hello from opium running on mirage os!! Server running at port %d"
          port) ;
    let config =
      { Tuyau_mirage_tcp.port
      ; Tuyau_mirage_tcp.keepalive= None
      ; Tuyau_mirage_tcp.nodelay= true
      ; Tuyau_mirage_tcp.stack }
    in
    Tuyau_mirage.serve ~key:Paf.TCP.configuration config
      ~service:Paf.TCP.service
    >>= function
    | Error err ->
        Lwt.return_error err
    | Ok (tcp_service, _) ->
          Paf.http
            ~request_handler:(fun _ -> request_handler)
            ~error_handler:(fun _ -> error_handler)
            tcp_service
end
