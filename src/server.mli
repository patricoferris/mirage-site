(* Our server needs to send data to our clients this entails
 * having the static files to send (FS = Filesystem) and the static 
 * content to fill blog posts (CONT = Content) - the last thing our 
 * server needs is some notion of time (CLOCK). 
*)
module Make 
  (S: Cohttp_lwt.S.Server)
  (FS: Mirage_kv.RO)
  (CONT: Mirage_kv.RO)
  (Clock: Mirage_clock.PCLOCK) :
sig 
  type s = Conduit_mirage.server -> S.t -> unit Lwt.t
  val start: s -> FS.t -> CONT.t -> unit -> unit Lwt.t
end 