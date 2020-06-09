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

