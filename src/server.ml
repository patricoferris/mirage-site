open Lwt.Infix
open Cohttp
let err fmt = Fmt.kstrf failwith fmt
let concat ss = String.concat "/" ss

module Make 
  (S: Cohttp_lwt.S.Server) 
  (SEC : Mirage_kv.RO)
  (R : Resolver_lwt.S) 
  (C : Conduit_mirage.S)
  (Clock : Mirage_clock.PCLOCK) = struct

  type s = Conduit_mirage.server -> S.t -> unit Lwt.t

  (* Logging Utils *)
  let log_src = Logs.Src.create "server" ~doc:"server"  
  module Log = (val Logs.src_log log_src : Logs.LOG)
  let log_info s = Log.info (fun f -> f "%s" s)

  (* The OAuth Authentication module *)
  module Auth = Oauth.Make(S) 

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
   * We can, at runtime, use Irmin to update the contents! *)
let sync ~conduit ~resolver =
  let upstream = Store.remote ~conduit ~resolver (Key_gen.git_remote ()) in
  Store.Repo.v (Irmin_mem.config ()) >>= Store.master  >>= fun t ->
  Log.info (fun f -> f "pulling repository") ;
  Lwt.catch
    (fun () ->
       Sync.pull_exn t upstream `Set >|= fun _ ->
       Log.info (fun f -> f "repository pulled"))
    (fun e ->
       Log.warn (fun f -> f "failed pull %a" Fmt.exn e);
       Lwt.return ())

 (* Querying the Irmin store for the blog and static content *)
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

  (* ~ Image handling ~ *)
  let image_handler store image = 
    let image = concat image in 
    let name_list = Fpath.(segs (of_string image |> function Ok d -> d | Error _ -> err "Malformed %s" image)) in
    content_read store name_list >>= fun body -> 
      match Fpath.get_ext (Fpath.v image) with
        | ".jpg" -> let headers = get_headers "image/jpg" (String.length body) in 
          S.respond_string ~headers ~body ~status:`OK ~flush:false ()
        | ".png" -> let headers = get_headers "image/png" (String.length body) in 
          S.respond_string ~headers ~body ~status:`OK ~flush:false ()
        | ".svg" -> let headers = get_headers "image/svg+xml" (String.length body) in 
          S.respond_string ~headers ~body ~status:`OK ~flush:false ()
        | _ -> S.respond_not_found ~uri:(Uri.of_string image) ()
        
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
  let static_file_handler store filename = 
    content_read store filename >>= function
      | body -> begin match Fpath.get_ext (Fpath.v (concat filename)) with
        | ".html" -> let headers = get_headers "text/html" (String.length body) in 
          S.respond_string ~headers ~body ~status:`OK ~flush:false ()
        | ".css" -> let headers = get_headers "text/css" (String.length body) in 
          S.respond_string ~headers ~body ~status:`OK ~flush:false ()
        | ".jpg" -> let headers = get_headers "image/jpg" (String.length body) in 
          S.respond_string ~headers ~body ~status:`OK ~flush:false ()
        | ".svg" -> let headers = get_headers "image/svg+xml" (String.length body) in 
          S.respond_string ~headers ~body ~status:`OK ~flush:false ()
        | ".yml" -> let headers = get_headers "text/yml" (String.length body) in 
          S.respond_string ~headers ~body ~status:`OK ~flush:false () 
        | _ -> S.respond_not_found ~uri:(Uri.of_string (concat filename)) ()
      end

  let serve_a_page page = 
    let body = (Pages.to_html page) in 
      let headers = get_headers "text/html" (String.length body) in 
      S.respond_string ~headers ~body ~status:`OK ~flush:false ()

  (* ~ The Router ~
   * Unsurprisingly handles sending data to clients. For blog posts 
   * it first has to generate the html instead of just sending down 
   * static files like the rest of the cases. *)
  let router gs cache resolver conduit req body uri = match uri with 
    (* Netlify CMS endpoints *)
    | ["admin"; ""] -> fun () -> static_file_handler gs.store ["admin"; "index.html"]
    | "admin" :: tl -> fun () -> static_file_handler gs.store uri 
    | ["config.yml"] -> fun () -> static_file_handler gs.store ["admin"; "config.yml"] 
    (* Main website endpoints *)
    | ["blogs"] -> fun () -> blog_page gs.store "blogs" 
    | ["about"] -> fun () -> serve_a_page Pages.about
    | "blogs" :: "images" :: tl as img -> fun () -> image_handler gs.store img
    | "blogs" :: tl -> fun () -> blog_handler gs.store ("blogs/" ^ (String.concat "" (tl @ [".md"]))) cache
    | "drafts" :: tl -> fun () -> blog_handler gs.store ("drafts/" ^ (String.concat "" (tl @ [".md"]))) cache
    (* Sync blog content *)
    | ["sync"] -> fun () -> sync ~resolver ~conduit >>= fun _ -> 
        Cache.flush cache;
        let body = "Succesful sync" in 
        let headers = get_headers "text/html" (String.length body) in 
        S.respond_string ~headers ~body ~status:`OK ~flush:false ()
    | [""] | ["/"] | ["index.html"] -> fun () -> serve_a_page Pages.index  
    (* Authentication with OAuth *)
    | ["auth"] -> fun () -> Auth.oauth_router ~resolver ~conduit ~req ~body ~client_id:(Key_gen.client_id ()) ~client_secret:(Key_gen.client_secret ()) ~uri  
    | [callback] when String.(equal (sub callback 0 8) "callback") -> 
      fun () -> Auth.oauth_router ~resolver ~conduit ~req ~body ~client_id:(Key_gen.client_id ()) ~client_secret:(Key_gen.client_secret ()) ~uri 
    | _ -> fun () -> static_file_handler gs.store ("static"::uri)

  let split_path path = 
    let dom::p = String.split_on_char '/' path in p 
  
  let create domain router =
    let hdr = match fst domain with `Http -> "HTTP" | `Https -> "HTTPS" in
    let callback _conn req body =
      let uri = Request.uri req |> Uri.path |> split_path in 
      router req body uri () in 
    let conn_closed (_,conn_id) =
      let cid = Cohttp.Connection.to_string conn_id in
      Log.debug (fun f -> f "[%s %s] OK, closing" hdr cid)
    in
    S.make ~callback ~conn_closed ()

  (* ~ TLS for Secure HTTP ~
   * X509 is the standard used for public key certificates.
   * https://github.com/mirage/mirage-skeleton/blob/master/applications/static_website_tls/dispatch.ml *)
   module X509 = Tls_mirage.X509(SEC)(Clock)

  (* ~ TLS Configurations ~ *)
  let tls_init secrets = 
    X509.certificate secrets `Default >>= fun cert -> 
    let configuration = Tls.Config.server ~certificates:(`Single cert) () in 
    Lwt.return configuration

  let start server secrets resolver conduit _clock =
    tls_init secrets >>= fun cfg -> (* Create the TLS config *)
    let host = Key_gen.host () in (* Get host name *)
    let port = Key_gen.https_port () in (* Get port for https *)
    let tls = `TLS (cfg, `TCP port) in (* Create a tls value using the port and configuration over TCP *)
    let remote = Key_gen.git_remote () in (* Git remote for blog content *)
    let domain = `Https , host in (* Domain for router *)
    init_blog_store ~resolver ~conduit ~uri:remote >>= fun gs ->  
    sync ~resolver ~conduit  >>= fun _ -> (* Syncing blog content initially *)
    let cache = Cache.create 10 in (* Creating the cache *)
    let callback = create domain (router gs cache resolver conduit) in
      server tls callback
end 
