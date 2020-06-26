---
authors:
  - Patrick Ferris
title: The MIM Stack
updated: June 25, 2020 6:51 PM
tags:
  - mirage
  - irmin
  - markdown
  - unikernel
---

W/out TLS :D 

![Convention OS Stack and Mirage Stack](/images/stack.svg)

MirageOS is a library operating system (OS) for building unikernels. Conventionally OSes are large programs that sit between hardware and applications providing an interface between them. In their quest to be useful in as many places as possible, they tend to grow very large and can seem cumbersome when you only want very specific parts of the OS. 

MirageOS brings the modularity of the "library" design principle to the OS world. Only include the parts you need, no more no less. This produces very lightweight unikernels with a very specific use-case (in this example a web server for a blog). 

MirageOS uses OCaml's module system along with a domain-specific language called [Functoria](https://github.com/mirage/mirage/tree/master/lib/functoria) to build unikernels targetting different backends. The user works with abstract notions of standard OS concepts like network stacks, block devices and Mirage fills in the details when you are ready to test or deploy. 

## The specification 

It's often useful to first outline what are the requirements of our system, this will help when it comes to building the unikernel. For a blog there are a few important aspects: 

- A web server: afterall it is a website so we will need some way to respond to HTTP requests.
- Markdown to HTML: as has become increasingly common in part to the [JAM stack](https://jamstack.org/) we want to remove all "techy" details from the actual content making it easier to write blogs and for others to contribute. 
- Git-based: whilst not obviously necessary, being git-based makes updating the content very easy (i.e. we won't have to rebuild the unikernel every time the content changes).

## The Unikernel

If this is your first time with OCaml and MirageOS might I suggest waiting for a blog post about [mirage](/drafts/mirage) (this a WIP). Alternatively you can use the [mirage.io](https://mirage.io/) website to learn more. 

The unikernel signature that will form our server is the following: 

```ocaml
module Make 
  (S: Cohttp_lwt.S.Server)
  (FS: Mirage_kv.RO)
  (R : Resolver_lwt.S)
  (C : Conduit_mirage.S) :
sig 
  type s = Conduit_mirage.server -> S.t -> unit Lwt.t
  val start: s -> FS.t -> Resolver_lwt.t -> Conduit_mirage.t -> unit Lwt.t
end 
```

This is a functor - we get a collection of modules as arguments and our job is to build a new module satisfying the structure described between `sig` and `end`. The `start` function will be called with the various implementations that we require of the modules. Each functor argument has a key purpose: 

- `Cohttp_lwt.S.Server`: this is our server for responding to HTTP requests, using it we can write ``S.respond_string ~headers ~body ~status:`OK ~flush:false ()`` which will reply to some incoming request. 
- `Mirage_kv.RO`: an abstract *read-only, key-value* mirage store used to respond with static files like the css files for instance.
- `Resolver_lwt.S` and `Conduit_mirage.S`: the unikernel has no way to communicate with the outside world! In particular, for Irmin to be able to pull in content from our remote git repository it needs a resolver and a conduit.   

## Generating HTML with TyXML PPX 

OCaml has the ability to extend its syntax using PPX-es, preprocessors that are applied to OCaml code before the compiler is called. Nathan Rebours has written a great introductory [article](https://tarides.com/blog/2019-05-09-an-introduction-to-ocaml-ppx-ecosystem) about them. 

Ocsigen have create a library, [TyXML](https://ocsigen.org/tyxml/4.4.0/manual/intro), which provides a way of generating statically correct HTML. They've also made a handy PPX that allows us to write HTML more naturally and still get compile time error checking. 

```ocaml
List.map 
  (fun link -> 
    [%html "<div><a href="link">"[Html.txt link]"</a></div>"]) 
  blogs
```

This short example comes directly from the [pages module](https://github.com/patricoferris/mirage-site/blob/master/src/pages.ml). We generate links to each of the blog posts being passed into the function (this is just the key from our Irmin store, more on that soon). 

## Irmin

Irmin is powerful library for creating and interacting with Git-like datastores. For this blog it creates an in-memory, key-value store using the Mirage backend for Irmin. 

With an in-memory Git store we can actually - at runtime - synchronise our content just like syncing a git repository with `git pull`! This means we can update our content, push to wherever we are holding it and synchronise our unikernel all without having to rebuild it.

To do this, the unikernel accepts a `git-remote` key. It then initialises the Irmin store and exposes an endpoint which can be used to synchronise the content of the blog. 

```ocaml
(* Building modules using functors *)
module Store = Irmin_mirage_git.Mem.KV(Irmin.Contents.String)
module Sync = Irmin.Sync(Store)

(* A type for holding stores and remotes *)
type git_store = {store: Store.t; remote: Irmin.remote}

(* Initialising the blog store with a uri and a repo *)
let init_blog_store ~resolver ~conduit ~uri = 
  let in_mem_config = Irmin_mem.config () in   
    Store.Repo.v in_mem_config >>= Store.master >|= fun repo -> 
    {store = repo; remote = Store.remote ~resolver ~conduit uri}
```

The `Store.t` is used for querying the contents of our in-memory datastore whilst the `Irmin.remote` is for syncing. Once we have the blog contents as markdown, it can be parsed to extract the metadata using a custom `Parser.YamlMarkdown` module which conveniently also produces an HTML document for the actual contents. 

To see how we can synchronise the content, have a look at the **router** section.

## Making a Server

A server is useless without some kind of routing - it must take requests for certain URIs and respond to them with sensible content. For example, if the router sees `patricoferris.com/blogs/compiler` it should find the `compiler.md` file, convert it to HTML and send this string back to the requesting user. 

To do this we use a callback and the `S.make` function from [this](https://github.com/mirage/ocaml-cohttp/blob/master/cohttp-lwt/src/s.ml) module. 

```ocaml
val make :
  ?conn_closed:(conn -> unit) ->
  callback:(conn -> Cohttp.Request.t -> Body.t ->
    (Cohttp.Response.t * Body.t) Lwt.t) ->
  unit ->
  t
```

From the signuate our callback should (ignoring the `conn` parameter) take a request and a request body and return a pair of a response and a response body. This is wrapped up in an `'a Lwt.t` monad which just means that it is a concurrent action. Any of the `respond_` functions from the same server module can do this. 

But first we must extract the path so we know which file to send as a response. To do this we take the `Cohttp.Request.t` and extract the important path information from it. 

```ocaml
(* Drops the domain name and splits along / *)
let split_path path = 
    let dom::p = String.split_on_char '/' path in p 

(* The callback function to be passes to S.make *)
let callback _conn req _body =
  let uri = Request.uri req |> Uri.path |> split_path in 
  router uri () in (*...*)
```

## The Router 

When building our callback function for our server, we passed the extracted URI to a `router` function. Let's now take a look at what it does. 

```ocaml
let router fs gs cache uri = match uri with 
  | ["blogs"] -> fun () -> blog_page gs.store "blogs" 
  | ["about"] -> fun () -> serve_a_page Pages.about
  | "blogs" :: tl -> 
    fun () -> blog_handler gs.store ("blogs/" ^ (String.concat "" (tl @ [".md"]))) cache
  | "images" :: tl -> 
    fun () -> static_file_handler fs tl
  | ["sync"] -> fun () -> sync gs.remote >>= fun _ -> 
    Cache.flush cache;
    let body = "Succesful sync" in 
    let headers = get_headers "text/html" (String.length body) in 
    S.respond_string ~headers ~body ~status:`OK ~flush:false ()
  | [""] | ["/"] | ["index.html"] -> fun () -> serve_a_page Pages.index
  | _ -> fun () -> static_file_handler fs uri
```

There's a lot going on here, let's take it piece by piece. The router takes four parameters: the filesystem (`fs`), the git store (`gs`), the `cache` and the `uri` to pattern-match on. The URI comes in as a list of the segments that make it up. For example, `blogs/unikernel` becomes `["blogs"; "unikernel"]`. 

If it only contains `blogs` then we serve the blogs index page. Most of the functions are defined in the [server](https://github.com/patricoferris/mirage-site/blob/master/src/server.ml) file. To do this we query the Irmin git store for a list of the nodes and produce HTML links to the appropriate pages. 

For an actual blog, we hand over control to a `blog_handler` function. The basic outline of this function is the following: 

1. Check if the blog is in the cache, in which case serve the already generated HTML content. 
2. If it isn't in the cache, query the Irmin store for the markdown content. 
3. Pass this content along to `Parser.YamlMarkdown.of_string` to generate the blog, cache it and serve the content. 
4. Handle any errors gracefully! 

