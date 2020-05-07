type t = Html of string

val gen_header : title:string -> css:t -> t
val wrapper : header:t -> body:t -> t 
(** Wraps body tags in HTML with a header pages in the standard page header *)