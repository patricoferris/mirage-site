type t = {
  authors: string list;
  updated: Date.t option;
  title: string;
  tags: string list option;
  subtitle: string option;
  content: Html.t
} (** The type of blog posts*)

val blog_home : blogs:t list ->  unit
(** Hmmm... a blog homepage for the future *)