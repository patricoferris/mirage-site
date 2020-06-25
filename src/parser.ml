open Blog

(* ~ A Parser ~ *
 * Containing modules for parsing different documents and producing
 * their data representations *)

(* ~ Yaml Frontmatter ~ 
* A parser for doing yaml front matter in the markdown *)
module YamlMarkdown = struct 
  type error = [`MalformedBlogPost of string]

  let empty_post : Blog.t = {
    authors = [];
    updated = None;
    title = "The Empty Post";
    tags = None; 
    subtitle = None;
    content = Tyxml.Html.(html (head (title (txt "Not found...")) []) (body [div [h1 [txt "🐫🐫🐫 Not Found 🐫🐫🐫"]]]))
  }

  let extract_yaml lines = 
    if String.equal (List.hd lines) "---" then 
      let rec yaml acc = function 
        | "---" :: ls -> Some (List.rev acc, ls)
        | l :: ls -> yaml (l::acc) ls 
        | _ -> None 
      in 
        yaml [] (List.tl lines)
    else 
      None

  let rec extract_string = function 
    | [] -> [] 
    | (`String s) :: xs -> s :: (extract_string xs)
    | x -> raise (Invalid_argument "Yaml expected list")

  let rec match_yaml (post : Blog.t) = function 
    | [] -> Some post 
    | ("authors", `A authors) :: xs -> match_yaml ({post with authors = (extract_string authors)}) xs 
    | ("tags", `A tags) :: xs -> match_yaml ({post with tags = (Some (extract_string tags))}) xs 
    | ("title", `String title) :: xs -> match_yaml ({post with title}) xs 
    | ("subtitle", `String subtitle) :: xs -> match_yaml ({post with subtitle = (Some subtitle)}) xs 
    | ("updated", `String updated) :: xs -> match_yaml ({post with updated = (Some updated)}) xs 
    | _ -> None

  let blogify yaml content = 
    let yaml = Yaml.of_string_exn (String.concat "\n" yaml) in 
    let build_post (pairs : Yaml.value) = match pairs with 
      | (`O kvpairs) -> match_yaml empty_post kvpairs
      | _ -> None in
    let post = build_post yaml in match post with 
      | Some post -> 
        let date = match post.updated with Some d -> d | None -> "" in               
        Ok ({post with content = Pages.page_template ~date ~title:post.title ~content:(Omd.(to_html (of_string content))) })
      | None -> Error (`MalformedBlogPost ("Building Failed: " ^ content))

  let of_string content = 
    (* Extract the YAML header *)
    let lines = String.split_on_char '\n' content in 
    let yaml_body = extract_yaml lines in match yaml_body with 
      | Some (yaml, body) -> blogify yaml (String.concat "\n" body) 
      | None -> Error (`MalformedBlogPost ("Extracting Yaml Failed: " ^ content))
end 
