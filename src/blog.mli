type t = {
  authors: string list;
  updated: Date.t option;
  title: string;
  tags: string list option;
  subtitle: string option;
  content: Html.t
}

val blog_home : blogs:t list ->  unit

val serve: blogs:(string * ([> `Not_found ] as 'a)) list -> (string -> 'a) Lwt.t
(** A function for serving blog posts *) 