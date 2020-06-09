# A MirageOS Unikernel Website 
-------------------------------

This is a personal website build using the MirageOS Library Operating System. It uses the following libraries to make it happen: 

- [TyXML](http://ocsigen.org/tyxml/4.4.0/manual/intro) for serving statically correct HTML.
- [Irmin](https://irmin.io/) to build an in-memory git store to hold the blog content (syncable without rebuilding the site!).
- [Omd](https://opam.ocaml.org/packages/omd/) parses the blogs in markdown and converts to HTML. 
- [Yaml](https://github.com/avsm/ocaml-yaml) for parsing the YAML frontmatter on the blog posts. 

The main purposes for this site are (1) to learn about MirageOS and building Unikernels and (2) to host my blog posts on computer science related things. 

The site draws a lot of inspiration and direction from already existing website unikernels: 

- [Dinosaure](https://github.com/dinosaure/blog.x25519.net/)'s blog using Irmin and Mirage. 
- [Canopy](https://github.com/Engil/Canopy) - a generalised version of what I'm making.  
- [Hannes](https://twitter.com/h4nnes)'s very detailed and very excellent [blog](https://hannes.nqsb.io/Posts/nqsbWebsite) about building something similar!