---
author: Patrick Ferris 
title: CMM, Mach and Linear
date: 2020-01-22
tags:
  - compiler
  - ocaml 
  - assembly
---

There's light at the end of tunnel - or pipeline. Let's recap where we are and what we've done to get here. We started at the beginning of the pipeline with our source code. A `ml` file written in OCaml. We checked it was good OCaml by lexing and parsing the source code. From this we made an abstract syntax tree. A compiler friendly interpretation of your program. We then type checked our program to make sure we didn't try and do something like `(fun a -> a + 5) "Hello"`. 

