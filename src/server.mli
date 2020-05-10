(* Our server needs to send data to our clients this entails
 * having the static files to send (FS = Filesystem)- the last thing our 
 * server needs is some notion of time (CLOCK). 
*)
module Make 
  (S: Cohttp_lwt.S.Server)
  (FS: Mirage_kv.RO)
  (R : Resolver_lwt.S)
  (C : Conduit_mirage.S)
  (Clock: Mirage_clock.PCLOCK) :
sig 
  type s = Conduit_mirage.server -> S.t -> unit Lwt.t
  val start: s -> FS.t -> Resolver_lwt.t -> Conduit_mirage.t -> unit -> unit Lwt.t
end 