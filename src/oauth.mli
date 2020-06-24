module Make (S: Cohttp_lwt.S.Server) (C: Cohttp_lwt.S.Client) : sig 
  val oauth_router : 
    req: Cohttp.Request.t -> 
    body: Cohttp_lwt.Body.t ->
    client_id:string ->
    client_secret:string ->  
    uri:string list -> 
    (Cohttp.Response.t * Cohttp_lwt.Body.t) Lwt.t
end 
