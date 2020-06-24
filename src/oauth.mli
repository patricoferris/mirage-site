module Make (S: Cohttp_lwt.S.Server) : sig 
  val oauth_router :
    resolver:Resolver_lwt.t -> 
    conduit:Conduit_mirage.t ->  
    req:Cohttp.Request.t -> 
    body:Cohttp_lwt.Body.t ->
    client_id:string ->
    client_secret:string ->  
    uri:string list -> 
    (Cohttp.Response.t * Cohttp_lwt.Body.t) Lwt.t
end 
