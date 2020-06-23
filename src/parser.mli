module YamlMarkdown: sig 
  type error = [`MalformedBlogPost of string]
  val of_string: string -> (Blog.t, error) result
  (** Converts a blog in YamlMarkdown format to Html *)
end 