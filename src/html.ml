type t = Html of string 

let (++) a b = 
  let Html content_a = a in 
  let Html content_b = b in Html (content_a ^ content_b)

let to_string html = let Html str = html in str

let gen_header ~title ~css = 
  let hd = Printf.sprintf "<head>
      <meta charset=\"UTF-8\">
      <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
      <meta http-equiv=\"X-UA-Compatible\" content=\"ie=edge\">
      %s
      <title>%s</title>
  </head>" (to_string css) title in Html hd

let wrapper ~header ~body = 
  Html "<html>" ++ header ++ body ++ Html "</html>"