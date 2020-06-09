val wrapper : 
  title:string ->
  content:[< Html_types.body_content_fun > `PCDATA ] Tyxml.Html.elt Tyxml.Html.list_wrap ->
  Tyxml.Html.doc

val index : Tyxml.Html.doc
val page_template : title:string  -> content:string -> Tyxml.Html.doc
val blog_page : string list -> Tyxml.Html.doc
val about : Tyxml.Html.doc
val to_html : Tyxml.Html.doc -> string 