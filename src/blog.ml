type t = {
  authors: string list;
  updated: Date.t option; 
  title: string;
  tags: string list option;
  subtitle: string option;
  content: Html.t;
}

let blog_home ~blogs = ()
  
let serve ~blogs = 
  let blog_entry x =
    try List.assoc x blogs
    with Not_found -> `Not_found 
  in 
  let f = function 
    | "index.html" | "" -> `Not_found
    | x -> blog_entry x
  in 
    Lwt.return f 
