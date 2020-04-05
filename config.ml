open Mirage

let packages =
  let tuyau = "git+https://github.com/dinosaure/tuyau.git" in
  let paf = "git+https://github.com/dinosaure/paf-le-chien.git" in
  let opium = "git+https://github.com/anuragsoni/opium#httpaf-update" in
  [ package "httpaf"
  ; package ~pin:opium "opium_kernel"
  ; package ~pin:tuyau "tuyau"
  ; package ~pin:tuyau "tuyau-tls"
  ; package ~pin:tuyau ~sublibs:["tcp"; "tls"] "tuyau-mirage"
  ; package ~pin:paf "paf" ]

let port =
  let doc = Key.Arg.info ~doc:"port to use for HTTP service" ["p"; "port"] in
  Key.(create "port" Arg.(opt int 8080 doc))

let server =
  foreign "Unikernel.Server" ~keys:[Key.abstract port]
    (console @-> time @-> stackv4 @-> job)

let stack = generic_stackv4 default_network

let () =
  register "server" ~packages [server $ default_console $ default_time $ stack]
