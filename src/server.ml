open Lwt.Infix
open Cohttp
let err fmt = Fmt.kstrf failwith fmt
let concat ss = String.concat "/" ss

module Make (S: Cohttp_lwt.S.Server) (FS: Mirage_kv.RO) (R : Resolver_lwt.S) (C : Conduit_mirage.S) (Clock: Mirage_clock.PCLOCK) = struct
  type s = Conduit_mirage.server -> S.t -> unit Lwt.t

  let log_src = Logs.Src.create "server" ~doc:"server"  
  module Log = (val Logs.src_log log_src : Logs.LOG)
  let log_info s = Log.info (fun f -> f "%s" s)

  (* ~ Reading Files ~ 
   * Using the FileSystem (FS) which is Mirage key-value stores.
   * They are Read-Only stores built using the static and blogs directories *)
  let file_read device key = FS.get device (Mirage_kv.Key.v key) >|= function 
    | Ok data -> data 
    | Error e -> err "%a" FS.pp_error e

  (* ~ Irmin + Mirage ~ 
   * Using Irmin we can create a Mirage KV_RO for blogs *)
  module Store = Irmin_mirage_git.Mem.KV(Irmin.Contents.String)
  module Sync = Irmin.Sync(Store)

  type git_store = {store: Store.t; remote: Irmin.remote}

  (* Initialising the blog store with a uri and a repo *)
  let init_blog_store ~resolver ~conduit ~uri = 
    let in_mem_config = Irmin_mem.config () in   
      Store.Repo.v in_mem_config >>= Store.master >|= fun repo -> 
      {store = repo; remote = Store.remote ~resolver ~conduit uri}

  (* ~ Irmin magic ~
   * We can, at runtime, use Irmin to update the KV store...*)
   let sync remote =
    let in_mem_config = Irmin_mem.config () in   
      Store.Repo.v in_mem_config >>= Store.master >>= fun t ->
      Sync.pull_exn t remote `Set

  (* To stay... Miragey the content has the same interface, a Mirage KV RO store... but we fill it from Irmin *)
  let content_read store name = 
    Store.find store name >|= function
      | Some data -> data
      | None -> err "%s" ("Could not find: " ^ (concat name))

  (* ~ A helper for headers ~
   * A little function for constructing HTTP headers *)
  let get_headers hdr_type length = 
    Cohttp.Header.of_list
      [ "content-length", string_of_int length;
        "content-type", hdr_type;
        "connection", "close" ]

  (* ~ Blog page ~ 
   * Extracting the blog posts to serve them as an index *)
  let blog_page store dir =
    Store.list store [dir] >|= List.map fst >>= fun blogs -> 
    let blogs = List.map (fun blog -> dir ^ "/" ^ (Filename.chop_extension blog)) blogs in 
    let body = Pages.(to_html (blog_page blogs)) in 
    let headers = get_headers "text/html" (String.length body) in 
      S.respond_string ~headers ~body ~status:`OK ~flush:false () 

  (* ~ Blog Handler ~ 
   * A helper function for constructing blog posts and serving them up! *)
  let blog_handler store blog_name cache = match Cache.find cache blog_name with 
    | Some blog -> log_info "Found in the cache!";
      let body = Blog.to_html blog in 
      let headers = get_headers "text/html" (String.length body) in 
        S.respond_string ~headers ~body ~status:`OK ~flush:false () 
    | None -> 
      let name_list = Fpath.(segs (of_string blog_name |> function Ok d -> d | Error _ -> err "Malformed %s" blog_name)) in
      let content = content_read store name_list >|= Parser.YamlMarkdown.of_string in 
      let response = content >>= (function 
        | Ok blog -> 
          Cache.put cache blog_name blog; 
          let body = Blog.to_html blog in 
          let headers = get_headers "text/html" (String.length body) in 
            S.respond_string ~headers ~body ~status:`OK ~flush:false () 
        | Error (`MalformedBlogPost e) -> S.respond_error ~body:(blog_name ^ " " ^ e) ()
        | Error _ -> S.respond_not_found ~uri:(Uri.of_string blog_name) ()
      ) in response

  (* ~ Static File Handler ~
   * Serves up files like index.html, main.css, javascript etc. *)
  let static_file_handler device filename = 
    let filename = if List.length filename == 1 then List.hd filename else "unknown" in 
    file_read device filename >>= function
      | body -> begin match Fpath.get_ext (Fpath.v filename) with
        | ".html" -> let headers = get_headers "text/html" (String.length body) in 
          S.respond_string ~headers ~body ~status:`OK ~flush:false ()
        | ".css" -> let headers = get_headers "text/css" (String.length body) in 
          S.respond_string ~headers ~body ~status:`OK ~flush:false ()
        | ".jpg" -> let headers = get_headers "image/jpg" (String.length body) in 
          S.respond_string ~headers ~body ~status:`OK ~flush:false ()
        | _-> S.respond_not_found ~uri:(Uri.of_string filename) ()
      end

  let serve_a_page page = 
    let body = (Pages.to_html page) in 
      let headers = get_headers "text/html" (String.length body) in 
      S.respond_string ~headers ~body ~status:`OK ~flush:false ()

  (* ~ The Router ~
   * Unsurprisingly handles sending data to clients. For blog posts 
   * it first has to generate the html instead of just sending down 
   * static files like the rest of the cases. *)
  let router fs gs cache uri = match uri with 
      | ["blogs"] -> fun () -> blog_page gs.store "blogs" 
      | ["about"] -> fun () -> serve_a_page Pages.about
      | "blogs" :: tl -> fun () -> blog_handler gs.store ("blogs/" ^ (String.concat "" (tl @ [".md"]))) cache
      | "images" :: tl -> fun () -> static_file_handler fs tl
      | ["sync"] -> fun () -> sync gs.remote >>= fun _ -> 
        Cache.flush cache;
        let body = "Succesful sync" in 
        let headers = get_headers "text/html" (String.length body) in 
        S.respond_string ~headers ~body ~status:`OK ~flush:false ()
      | [""] | ["/"] | ["index.html"] -> fun () -> serve_a_page Pages.index
      | _ -> fun () -> static_file_handler fs uri

  let split_path path = 
    let dom::p = String.split_on_char '/' path in p 
  
  let create domain router =
    let hdr = match fst domain with `Http -> "HTTP" | `Https -> "HTTPS" in
    let callback _conn req _body =
      let uri = Request.uri req |> Uri.path |> split_path in 
      router uri () in 
    let conn_closed (_,conn_id) =
      let cid = Cohttp.Connection.to_string conn_id in
      Log.debug (fun f -> f "[%s %s] OK, closing" hdr cid)
    in
    S.make ~callback ~conn_closed ()
  
  let start server fs resolver conduit () =
    let host = Key_gen.host () in 
    let remote = Key_gen.git_remote () in 
    let domain = `Http , host in 
    init_blog_store ~resolver ~conduit ~uri:remote >>= fun gs ->  
    sync gs.remote >>= fun _ -> 
    let cache = Cache.create 10 in 
    let callback = create domain (router fs gs cache) in
    let port = Key_gen.http_port () in 
    server (`TCP port) callback
end 