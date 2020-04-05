open Lwt.Infix

module Server
    (C : Mirage_console.S)
    (T : Mirage_time.S)
    (StackV4 : Mirage_stack.V4) =
struct
  module Paf = Paf.Make (T) (StackV4)

  let log console fmt = Format.ksprintf (C.log console) fmt

  module App = struct
    open Opium_kernel

    let uppercase =
      let filter service req =
        service req
        >|= fun ({Rock.Response.body; _} as res) ->
        let {Body.length; _} = body in
        let stream =
          Lwt_stream.map String.uppercase_ascii (Body.to_stream body)
        in
        let body' = Body.of_stream ?length stream in
        {res with Rock.Response.body= body'}
      in
      Rock.Middleware.create ~name:"uppercase" ~filter

    let service _req =
      Rock.Response.make ~body:(Body.of_string "Hello World") () |> Lwt.return

    let app = Rock.App.create ~middlewares:[uppercase] ~handler:service
  end

  let start c _time stack =
    let port = Key_gen.port () in
    log c "Hello from opium running on mirage os!! Server running at port %d"
      port
    >>= fun () ->
    let config =
      { Tuyau_mirage_tcp.port
      ; Tuyau_mirage_tcp.keepalive= None
      ; Tuyau_mirage_tcp.nodelay= true
      ; Tuyau_mirage_tcp.stack }
    in
    let app = App.app in
    Tuyau_mirage.serve ~key:Paf.TCP.configuration config
      ~service:Paf.TCP.service
    >>= function
    | Error err ->
        Lwt.return_error err
    | Ok (tcp_service, _) ->
        let f ~request_handler ~error_handler =
          Paf.http
            ~request_handler:(fun _ -> request_handler)
            ~error_handler:(fun _ -> error_handler)
            tcp_service
        in
        Opium_kernel.Server_connection.run f app
end
