open Lwt.Infix
open Cohttp
let err fmt = Fmt.kstrf failwith fmt

module Make (S: Cohttp_lwt.S.Server) (FS: Mirage_kv.RO) (CONT: Mirage_kv.RO) (Clock: Mirage_clock.PCLOCK) = struct
  type s = Conduit_mirage.server -> S.t -> unit Lwt.t
  let log_src = Logs.Src.create "dispatch" ~doc:"Web server"
  module Log = (val Logs.src_log log_src : Logs.LOG)
  
  let content_read content name = CONT.get content (Mirage_kv.Key.v name) >|= function
    | Ok data -> data
    | Error e -> err "%a" CONT.pp_error e

  let read_entry content name = content_read content name >|= Parser.YamlMarkdown.of_string 

  let blog cont =
    Parser. [] 

  let router fs cont = 
    let blogs = blog cont in 
    function 
    | "blog" -> Blog.serve blogs  
  
  let create domain router =
    let hdr = match fst domain with `Http -> "HTTP" | `Https -> "HTTPS" in
    let callback _conn req body =
      let uri = Request.uri req |> Uri.to_string in 
      let headers = req |> Request.headers |> Header.to_string in 
      let notfound ~uri = S.respond_not_found ~uri () in 
      body |> Cohttp_lwt.Body.to_string >|= (fun body ->
      (Printf.sprintf "Uri: %s\n Headers: %s\nBody: %s"
         uri headers body)) >>= (fun body -> S.respond_string ~status:`OK ~body ()) in 
    let conn_closed (_,conn_id) =
      let cid = Cohttp.Connection.to_string conn_id in
      Log.debug (fun f -> f "[%s %s] OK, closing" hdr cid)
    in
    S.make ~callback ~conn_closed ()
    

  let start server fs cont () =
    (* let x = content_read cont in *)
    let host = Key_gen.host () in 
    let domain = `Http , host in  
    let callback = create domain router in
    server (`TCP (Key_gen.http_port ())) callback
end 