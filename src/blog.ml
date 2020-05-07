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

let wrap_blog blog = 
  let title = blog.title in 
  let header = gen_header ~title ~css:(Html "<link rel=\"stylesheet\" href=\"/main.css\">") in 
  let content = blog.content in 
    {blog with content = wrapper ~header ~body:content}

let not_found = {
  authors = [" Not Found "];
  updated = None; 
  title = "Page Not Found"; 
  tags = None; 
  subtitle = None; 
  content = Html "Not Found :("
}
