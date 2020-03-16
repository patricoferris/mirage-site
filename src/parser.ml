open Blog
open Html

module YamlMarkdown = struct 
  type t = Html.t
  type error = [`MalformedBlogPost of string]

  let empty_post : Blog.t = {
    authors = [];
    updated = Some (Date.datify 1998 "December" 25);
    title = "The Empty Post";
    tags = None; 
    subtitle = None;
    content = Html ""
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

  let parse_date date = 
    match String.split_on_char '-' date with  
    | year::month::day::[] -> Some (Date.datify (int_of_string year) month (int_of_string day))
    | _ -> None 

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
    | ("updated", `String updated) :: xs -> match_yaml ({post with updated = (parse_date updated)}) xs 
    | _ -> None 

  let blogify yaml content = 
    let yaml = Yaml.of_string_exn (String.concat "\n" yaml) in 
    let build_post (pairs : Yaml.value) = match pairs with 
      | (`O kvpairs) -> match_yaml empty_post kvpairs
      | _ -> None in 
    let post = build_post yaml in match post with 
      | Some post -> Ok ({post with content = Html (Omd.to_html (Omd.of_string content))})
      | None -> Error (`MalformedBlogPost content)

  let of_string content = 
    (* Extract the YAML header *)
    let lines = String.split_on_char '\n' content in 
    let yaml_body = extract_yaml lines in match yaml_body with 
      | Some (yaml, body) -> blogify yaml (String.concat "\n" body) 
      | None -> Error (`MalformedBlogPost content)
end 