open Lwt.Infix
open Cohttp
let err fmt = Fmt.kstrf failwith fmt

module Make (S: Cohttp_lwt.S.Server) (FS: Mirage_kv.RO) (CONT: Mirage_kv.RO) (Clock: Mirage_clock.PCLOCK) = struct
  type s = Conduit_mirage.server -> S.t -> unit Lwt.t

  let log_src = Logs.Src.create "dispatch" ~doc:"Web server"  
  module Log = (val Logs.src_log log_src : Logs.LOG)

  (* ~ Reading Files ~ 
   * Using the FileSystem and CONTent modules which are Mirage key-value stores.
   * They are Read-Only stores built using the static and blogs directories *)
  let file_read device key = FS.get device (Mirage_kv.Key.v key) >|= function 
    | Ok data -> data 
    | Error e -> err "%a" FS.pp_error e
  
  let content_read content name = CONT.get content (Mirage_kv.Key.v name) >|= function
    | Ok data -> data
    | Error e -> err "%a" CONT.pp_error e

  let read_entry content name = content_read content name >|= Parser.YamlMarkdown.of_string 

  (* ~ A helper for headers 
   * A little function for constructing HTTP headers *)
  let get_headers hdr_type length = 
    Cohttp.Header.of_list
      [ "content-length", string_of_int length;
      "content-type", hdr_type;
      "connection", "close" ]

  (* ~ Blog Handler ~ 
   * A helper function for constructing blog posts and serving them up! *)
  let blog device blog_name =
    let content = content_read device blog_name >|= Parser.YamlMarkdown.of_string in 
    let response = content >>= (function 
      | Ok blog -> 
        let Html body = blog.content in 
        let headers = get_headers "text/html" (String.length body) in 
          S.respond_string ~headers ~body ~status:`OK ~flush:false () 
      | Error (`MalformedBlogPost e) -> S.respond_error ~body:(blog_name ^ " " ^ e) ()
      | Error _ -> S.respond_not_found ~uri:(Uri.of_string blog_name) ()
     ) in response


  (* ~ The Router ~
   * Unsurprisingly handles sending data to clients. For blog posts 
   * it first has to generate the html instead of just sending down 
   * static files like the rest of the cases. *)
  let router _fs cont uri = 
    let body = "<h1>Hi</h1>" in 
    let headers = get_headers "text/html" (String.length body) in match uri with  
      | [""] | ["index.html"] -> S.respond_string ~headers ~body ~status:`OK ~flush:false
      | "blog" :: tl -> fun () -> blog cont (String.concat "" (tl @ [".md"])) 
      | _ -> S.respond_string ~headers ~body:"hmmm!" ~status:`OK ~flush:false
    

  let split_path path = 
    let dom::p = String.split_on_char '/' path in p 
  
  let create domain router =
    let hdr = match fst domain with `Http -> "HTTP" | `Https -> "HTTPS" in
    let callback _conn req body =
      let uri = Request.uri req |> Uri.path |> split_path in 
      router uri () in 
    let conn_closed (_,conn_id) =
      let cid = Cohttp.Connection.to_string conn_id in
      Log.debug (fun f -> f "[%s %s] OK, closing" hdr cid)
    in
    S.make ~callback ~conn_closed ()
  
  let start server fs cont () =
    (* let x = content_read cont in *)
    let host = Key_gen.host () in 
    let domain = `Http , host in  
    let callback = create domain (router fs cont) in
    let port = Key_gen.http_port () in 
    server (`TCP port) callback
end 