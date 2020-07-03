open Tyxml

let header_wrapper ~title ~content = [%html{|
  <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="X-UA-Compatible" content="ie=edge">
      <title>|} (Html.txt title) {|</title>
      <link href="https://fonts.googleapis.com/css2?family=Roboto+Mono&family=Ubuntu:ital,wght@0,400;0,700;1,400&display=swap" rel="stylesheet">
      <link rel=stylesheet href="/main.css" />
      <link rel="stylesheet"  href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/10.0.0/styles/gruvbox-dark.min.css">
      <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/10.0.0/highlight.min.js"></script>
      <script charset="UTF-8" src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/10.0.0/languages/ocaml.min.js"></script>
      <script>hljs.initHighlightingOnLoad();</script>
    <script src="https://identity.netlify.com/v1/netlify-identity-widget.js"></script>
      </head>
    <body>|} content {|
    </body>
  </html>
|}]

let simple_list ~items = 
  let items = (List.map (fun item -> [%html "<li>"[Html.txt item]"</li>"]) items) in 
  [%html{|
  <ul>
    |} items {|
  </ul>
|}]

let nav_bar = [%html {|
<div id="nav" class="container-three-by-one">
   <div class="one-one">
     <a style="color: black" href="https://twitter.com/patricoferris">
       @patricoferris
     </a>
   </div>
   <div class="nav-buttons" style="width: 100%;">
    <div class="container-three-by-one">
      <div class="one-one"><a href="/">home</a></div>
      <div class="one-two"><a href="/about">about</a></div>
      <div class="one-three"><a href="/blogs">blog</a></div>
    </div>
  </div>
</div>|}]
