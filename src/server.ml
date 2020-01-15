
module Run (S: Cohttp_lwt.S.Server) (FS: Mirage_kv.RO) = struct

  (* Logging *)
  let log_src = Logs.Src.create "dispatch" ~doc:"Web server"
  module Log = (val Logs.src_log log_src : Logs.LOG)
  
  (* Simple regex to extract subpages *)
  let strip str = 
    let re = Re2.create_exn "\\/(\\w*)" in 
      match Re2.find_all re str with
      | Core_kernel.Result.Ok s -> List.nth s ((List.length s) - 1)
      | Core_kernel.Result.Error _ -> ""

  let router = function 
    | "/" -> "index.html"
    | _   -> "404.html"

  let create domain =
    let hdr = match fst domain with `Http -> "HTTP" | `Https -> "HTTPS" in
    let callback _conn req body =
      let uri = Cohttp.Request.uri req |> Uri.to_string in 
      body |> Cohttp_lwt.Body.to_string |> (fun _body -> 
      let fname = router (strip uri) in 
        (S.respond_string ~status:`OK ~body:fname ())) in
    let conn_closed (_,conn_id) =
      let cid = Cohttp.Connection.to_string conn_id in
      Log.debug (fun f -> f "[%s %s] OK, closing" hdr cid) in
    S.make ~callback ~conn_closed ()

  let start server _filesystem =
    let host = Key_gen.host () in 
    let domain = `Http , host in  
    let callback = create domain in
    server (`TCP (Key_gen.http_port ())) callback
end 