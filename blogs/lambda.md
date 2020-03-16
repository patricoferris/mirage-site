---
author: Patrick Ferris 
title: A Tale of Two Lambdas
date: 2020-01-22
tags:
  - compiler
    ocaml 
    assembly
---

Parsed and type-checked. We are now somewhere deep in the pipeline with seemingly no end in sight. Our focus is now on getting down to machine code. As we've seen, each stage of the pipeline is removing levels of abstraction. Assembly is not typed... or [is it](https://www.cs.cornell.edu/talc/). When we're running on a CPU the notion of a module is not important - we need the instruction by instruction sequence that is going to run the program we want. 

Intermediate representations (IR) are like programming languages. Thanks to the parsing they are often tree-like structures with information about our program. In OCaml (as with many things in the language) they take the form of s-expressions. Let's take a moment to briefly go over this (Lisp programmers feel free to jump ahead). 

Symbolic expressions (sexp) are a form of data representation. They are particularly nice to work with when your datatypes are recursive in nature like the following types.

```ocaml
type 'a list = Nil | Cons of 'a * 'a list 
type 'a tree = Leaf | Branch of 'a tree * 'a * 'a tree 
```

They are recursive because some of their constructors use the data type we are defining in their definition. S-expressions are really like a bracketed form of the datatype. Say we have the list `[1;2;3]`. This is syntactic sugar for the true underlying representation. 


```ocaml
Cons (1, Cons (2, Cons (3, Nil)))
```

Hopefully you can see how this would be useful given the input to this stage of the pipeline is our typed *tree*. Originally if we had the following expression `2 + 3 + 4` we would have constructed the tree. We now look at the equivalent s-expression. 

```
(* Tree Format *)
        +
      /   \
     +     4
   /   \
  2     3

(* S-Expression *)
(+ (+ 2 3) 4)
```