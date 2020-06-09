open Tyxml

type t = {
  authors: string list;
  updated: Date.t option; 
  title: string;
  tags: string list option;
  subtitle: string option;
  content: Tyxml.Html.doc;
}

let blog_temp content = [%html
    "<div class='content'>"[content]"</div>"
]

let to_html blog = Format.asprintf "%a" (Tyxml.Html.pp ()) blog.content;;

let not_found = {
  authors = [" Not Found "];
  updated = None; 
  title = "Page Not Found"; 
  tags = None; 
  subtitle = None; 
  content = Tyxml.Html.(html (head (title (txt "Not found...")) []) (body [div [h1 [txt "🐫🐫🐫 Not Found 🐫🐫🐫"]]]))
}
