open Tyxml

type t = {
  authors: string list;
  updated: Date.t option;
  title: string;
  tags: string list option;
  subtitle: string option;
  content:  Tyxml.Html.doc;
} (** The type of blog posts*)

val to_html : t -> string 
