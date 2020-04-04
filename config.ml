open Mirage

let packages = [ package "opium_kernel" ]

let port =
  let doc = Key.Arg.info ~doc:"port to use for HTTP service" ["p"; "port"] in
  Key.(create "port" Arg.(opt int 8080 doc))

let server =
  foreign "Unikernel.Server"
  ~keys:[Key.abstract port]
  (console @-> stackv4 @-> resolver @-> conduit @-> job)

let stack = generic_stackv4 default_network
let conduit = conduit_direct stack
let resolver = resolver_dns stack

let () =
  register "server"
  ~packages [ server $ default_console $ stack $ resolver $ conduit ]
