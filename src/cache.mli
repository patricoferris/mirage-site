type ('a, 'b) t 
(** The type of caches *)

val create : int -> ('a, 'b) t

val find : ('a, 'b) t -> 'a -> 'b option 
(** Given a cache with a key [k] finds the value [v] or returns [None] *)

val flush : ('a, 'b) t -> unit
(** Empties the cache *)

val put : ('a, 'b) t -> 'a -> 'b -> unit 
(** Adds an entry to the cache *)