type t = Html of string
val (++) : t -> t -> t
val gen_header : title:string -> css:t -> t
val gen_css : t 
val wrapper : header:t -> body:t -> t 
(** Wraps body tags in HTML with a header pages in the standard page header *)
val wrap : before:t -> after:t -> content:t -> t 
(** Wraps some HTML around a given piece of HTML *)