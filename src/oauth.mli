module Make (S: Cohttp_lwt.S.Server) (C: Cohttp_lwt.S.Client) : sig 
  val oauth_router : 
    req: Cohttp.Request.t -> 
    body: Cohttp.Body.t ->
    client_id:string -> 
    uri:string list -> 
    (Cohttp.Response.t * Cohttp_lwt__.Body.t) Lwt.t
end 