open Tyxml

let index = [%html {|
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <link href="https://fonts.googleapis.com/css2?family=Ubuntu:ital,wght@0,400;0,700;1,400&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/main.css">
    <title>Patrick Ferris</title>
  </head>
  <body> 
    <div id="nav" class="container-three-by-one">
      <div class="one-one">@patricoferris</div>
      <div class="nav-buttons" style="width: 100%;">
        <div class="container-three-by-one">
          <div class="one-one"><a href="/">home</a></div>
          <div class="one-two"><a href="/about">about</a></div>
          <div class="one-three"><a href="/blogs">blog</a></div>
        </div>
      </div>
    </div>
    <div class="content">
      <div class="container-two-by-one">
        <div class="one-one">
          <img style="width: 100%;" src="./me.jpg" alt="A picture of the author standing in Pembroke College, Cambridge">
        </div>
        <div class="one-two">
          <h3>Yep, another computer scientist's <em>corner of the web</em>... at least it's a MirageOS Unikernel!</h3>
        </div>
      </div>
    </div>
  </body>
  </html>
|}]

let page_template ~title ~content = 
  let content = Html.Unsafe.data content in
  let html = [%html {|
  <div id="nav" class="container-three-by-one">
    <div class="one-one">@patricoferris</div>
    <div class="nav-buttons" style="width: 100%;">
      <div class="container-three-by-one">
        <div class="one-one"><a href="/">home</a></div>
        <div class="one-two"><a href="/about">about</a></div>
        <div class="one-three"><a href="/blogs">blog</a></div>
      </div>
    </div>
  </div>
  <div class="content">
  <h1>|} [Html.txt title] {|</h1>|}[content]{|</div>
|}] in Components.header_wrapper ~title ~content:html

let blog_page blogs = 
  let content = List.map (fun link -> [%html "<div><a href="link">"[Html.txt link]"</a></div>"]) blogs in
  let content = [%html "<div class=content><h1>Blog Posts</h1><div class=flex>"content"</div></div>"] in
  Components.header_wrapper ~title:"Blog Posts" ~content:[content]

let about = 
  let passions = [
    {|Open Source Projects: whether its hardware or software I think open source projects are great. 
      They provide a great opportunity for more people to get involved with technology and for more non-profit 
      oriented projects to get off the ground |};
    {|OCaml and MirageOS: when I first learnt about functional programming I didn't get it, now it's hard not to use it. 
      MirageOS is a library operating system for building unikernels - they are small, low-power, secure OSes.|};
    {|RISC-V: the open source specification for a RISC ISA which enables anybody to build their own processors and extend them
      in whatever way suits them - there is a big opportunity here for developing highly specialised, secure, low-power processors.|};
    {|Environmentalism: it's probably somewhat obvious from the number of times I said "low-power" but the tech industry has a duty to 
      (a) lower its carbon footprint and (b) providing tooling for tackling climate change.|}] in 
  let content = [%html {|
    <div class="container-three-by-one nav">
      <div class="one-one">@patricoferris</div>
      <div class="nav-buttons" style="width: 100%;">
        <div class="container-three-by-one">
          <div class="one-one"><a href="/">home</a></div>
          <div class="one-two"><a href="/about">about</a></div>
          <div class="one-three"><a href="/blogs">blog</a></div>
        </div>
      </div>
    </div>
    <div class="content">
    <p>I'm a recent graduate from Pembroke College, Cambridge in Computer Science.</p>
    <p>Some of my passions include:</p>
    |} [Components.simple_list ~items:passions] {|
    </div>
  |}] in Components.header_wrapper ~title:"About" ~content

let to_html doc = Format.asprintf "%a" (Tyxml.Html.pp ()) doc
