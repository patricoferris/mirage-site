module YamlMarkdown: sig 
  type t = Html.t  
  type error = [`MalformedBlogPost of string]
  val of_string: string -> (Blog.t, error) result
  (** Converts a blog in YamlMarkdown format to Html *)
end 