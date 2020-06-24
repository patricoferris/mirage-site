open Lwt.Infix

module Json = Yojson.Basic 
let split = String.split_on_char 

let script msg = "
<script>  
  (function() {
    function recieveMessage(e) {
      console.log('recieveMessage %o', e);
      // send message to main window with the app
      console.log(" ^ msg ^ ")
      window.opener.postMessage(
        'authorization:github:success:" ^ msg ^ "', 
        e.origin
      );
    }
    window.addEventListener('message', recieveMessage, false);
    window.opener.postMessage('authorizing:github', '*');
  })()
</script>
"

module Make (S : Cohttp_lwt.S.Server) = struct
  module C = Cohttp_mirage.Client  
  let auth_url client_id = "https://github.com/login/oauth/authorize?client_id=" ^ client_id ^ "&scope=repo,user`"
  let token_url = "https://github.com/login/oauth/access_token"

  let extract_code query = 
    let questions = split '?' query in 
    let equals = List.flatten (List.map (split '=') questions) in 
    let apersand = List.flatten (List.map (split '&') equals) in 
    let rec get_code = function 
      | [] -> failwith "Error: couldn't find code query parameter"
      | "code" :: value :: _ -> value 
      | _ :: ls -> get_code ls 
    in 
      get_code apersand 

  let build_post ~code ~client_id ~client_secret =
    let json = `Assoc [("client_id", `String client_id); ("client_secret", `String client_secret); ("code", `String code)] in 
      Json.to_string json
  
  let oauth_post ctx req client_id client_secret = 
    let code = extract_code (Cohttp.Request.resource req) in
    let body = Cohttp_lwt.Body.of_string @@ build_post ~code ~client_id ~client_secret in
    let headers = Cohttp.Header.of_list [("Content-Type", "application/json"); ("Accept", "application/json")] in 
      C.post ~ctx ~headers ~body (Uri.of_string token_url) >>= fun (res, body) -> 
      Cohttp_lwt.Body.to_string body >>= fun body ->
        let json = Json.from_string body in 
        let token = List.hd (Json.Util.filter_member "access_token" [json]) in 
        let open Json.Util in 
        let msg = Json.to_string @@ `Assoc [("token", token); ("provider", `String "github")] in 
        let body = script msg in 
        let headers = Cohttp.Header.of_list
          [ "content-length", string_of_int (String.length body);
            "content-type", "text/html";
            "connection", "close" ] in
          S.respond_string ~headers ~body ~status:`OK ~flush:false () 

  let oauth_router ~resolver ~conduit ~req ~body ~client_id ~client_secret ~uri = match uri with 
    | ["auth"] -> S.respond_redirect (Uri.of_string (auth_url client_id)) ()
    | _ -> oauth_post (C.ctx resolver conduit) req client_id client_secret
end 
  
