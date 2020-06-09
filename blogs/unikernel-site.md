---
authors: 
  - Patrick Ferris 
title: A Git-backed, MirageOS Blog
updated: 2020-06-09
tags:
  - mirage
  - unikernel
---

MirageOS is a library operating system (OS) for building unikernels. Conventionally OSes are large programs that sit between hardware and applications providing an interface between them. In their quest to be useful in as many places as possible, they tend to grow very large and can seem cumbersome when you only want very specific parts of the OS. 

MirageOS brings the modularity of the "library" design principle to the OS world. Only include the parts you need, no more no less. This produces very lightweight unikernels with a very specific use-case (in this example a web server for a blog). 

MirageOS uses OCaml's module system along with a domain-specific language called [Functoria](https://github.com/mirage/mirage/tree/master/lib/functoria) to build unikernels targetting different backends. The user works with abstract notions of standard OS concepts like network stacks, block devices and Mirage fills in the details when you are ready to test or deploy. 

## The specification 

It's often useful to first outline what are the requirements of our system, this will help when it comes to building the unikernel. For a blog there are a few important aspects: 

- A web server: afterall it is a website so we will need some way to respond to HTTP requests.
- Markdown to HTML: as has become increasingly common in part to the [JAM stack](https://jamstack.org/) we want to remove all "techy" details from the actual content making it easier to write blogs and for others to contribute. 
- Git-based: whilst not obviously necessary, being git-based makes updating the content very easy (i.e. we won't have to rebuild the unikernel every time the content changes).

## The Server 

If this is your first time with OCaml and MirageOS might I suggest <INSERTOTHERBLOGHERE>. 

The unikernel signature that will form our server is the following: 

```ocaml
module Make 
  (S: Cohttp_lwt.S.Server)
  (FS: Mirage_kv.RO)
  (R : Resolver_lwt.S)
  (C : Conduit_mirage.S)
  (Clock: Mirage_clock.PCLOCK) :
sig 
  type s = Conduit_mirage.server -> S.t -> unit Lwt.t
  val start: s -> FS.t -> Resolver_lwt.t -> Conduit_mirage.t -> unit -> unit Lwt.t
end 
```

This is a functor - we get a collection of modules as arguments and our job is to build a new module satisfying the structure described between `sig` and `end`. The `start` function will be called with the various implementations that we require of the modules. Each functor argument has a key purpose: 

- `Cohttp_lwt.S.Server`: this is our server for responding to HTTP requests, using it we can write ``S.respond_string ~headers ~body ~status:`OK ~flush:false ()`` which will reply to some incoming request. 
- `Mirage_kv.RO`: an abstract *read-only key-value* mirage store, we will this "File System" to respond with static files like the css files for instance.
- `Resolver_lwt.S`: 


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

Irmin is powerful library for creating and interacting with Git-like datastores. For this blog, it creates an in-memory key-value store using the Mirage backend for Irmin. 

With an in-memory Gite store we can actually - at runtime - sync our content just like syncing a git repository with `git pull`! This means we can update our content, push to wherever we are holding it and synchronise our unikernel all without having to rebuild it.

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

The `Store.t` is used for querying the contents of our in-memory datastore whilst the `Irmin.remote` is for syncing. 