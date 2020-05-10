open Html

type t = {
  authors: string list;
  updated: Date.t option; 
  title: string;
  tags: string list option;
  subtitle: string option;
  content: Html.t;
}

let blog_home ~blogs = 
  let build_component blog = 
    Html "<div>" ++
      Html blog.title ++
    Html "</div>" in
  let blog_components = List.map build_component blogs in
    List.fold_left (fun acc comp -> acc ++ comp) (Html "") blog_components

let wrap_blog blog = 
  let title = blog.title in 
  let content_div = wrap ~before:(Html "<div class=\"content\">") ~after:(Html "</div>") in 
  let css = gen_css ++ (Html "<link rel=\"stylesheet\" href=\"/main.css\">") in 
  let header = gen_header ~title ~css in 
  let content = content_div blog.content in 
    {blog with content = wrapper ~header ~body:content}

let not_found = {
  authors = [" Not Found "];
  updated = None; 
  title = "Page Not Found"; 
  tags = None; 
  subtitle = None; 
  content = Html "<h1>🐫🐫🐫 Not Found 🐫🐫🐫</h1>"
}
