val header_wrapper : 
  title:string ->
  content:[< Html_types.body_content_fun > `PCDATA ] Tyxml.Html.elt Tyxml.Html.list_wrap ->
  Tyxml.Html.doc

val simple_list : items:string list -> [> Html_types.ul ] Tyxml_html.elt
val nav_bar : [> Html_types.div ] Tyxml_html.elt