open Lwt.Infix

module Server (C : Mirage_console.S) (StackV4 : Mirage_stack.V4) (Resolver : Resolver_lwt.S) (Conduit : Conduit_mirage.S) = struct
  let start _c _stack _resolver _conduit =
    Lwt.return ()
end
