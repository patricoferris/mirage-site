open Html

type t = {
  authors: string list;
  updated: Date.t option; 
  title: string;
  tags: string list option;
  subtitle: string option;
  content: Html.t;
}

let blog_home ~blogs = ()

let not_found = {
  authors = [" Not Found "];
  updated = None; 
  title = "Page Not Found"; 
  tags = None; 
  subtitle = None; 
  content = Html "Not Found :("
}
