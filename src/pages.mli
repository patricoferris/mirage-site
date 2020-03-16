type t = Cow.Html.t Lwt.t
(** A page *)

module Wrapper: sig 
  val t : header:Cow.Html.t -> body:Cow.Html.t -> t 
  (** Wraps other HTML pages in the standard page*)
end 

module Home: sig 
  val t: title:string -> headers:Cow.Html.t -> content:Cow.Html.t -> t
end 