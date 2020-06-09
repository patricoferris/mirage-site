---
authors: 
  - Patrick Ferris 
title: OCaml types - Beyond variants and records
updated: 2020-01-22
tags:
  - types
  - intermediate
---

In this post we'll look at using some of the more *advanced* types in OCaml to make real-world applications. What you can hopefully expect to learn will be a little bit of some of the more "difficult" types including: 

- Parameterised Types 
- Polymorphic Variants 
- General Abstract Data Types 
- Some weird OCaml types 

For each of these I'll try and introduce the main concepts, some toy examples which help show why there are useful and then links to them in the *wild* being used in projects and OCaml code. 

On your OCaml journey so far it is likely that you have encountered two main ways to define a new type - variants and records (sums and products).  

```ocaml
type vehicle = Car of int | Bicycle of int | Unicycle of int 
type person = { age: int; name: string }
```

And hopefully you've seen you these can be recursive too - using the type declaration in the definition of the type. This is how a lot of recursive data structures can be created, most notably the list. 

```ocaml
type int lst = Nil | Cons of int 
```

Are first stop on this types tour is with parameterised types. The name is quite descriptive and the list data structure is ripe for "parameterisation"! Why? Whether I have a list of `vehicles` or `person` or `int`, nothing has really changed but we don't want to have to define for every single list a new type declaration just to change the `Cons of int` constructor. So instead we leave a variable (a parameter) in its place and let the type checker figure out later what we really wanted depending on the context it sees our list. 

```ocaml
type 'a lst = Nil | Cons of 'a
```

Why the apostrophe before the `a`? We need some way to tell the compiler "I'm not naming this type, I'm creating a type variable". You can to a certain extent think of these as functions over types rather than values. We even get some of the same errors: 

```ocaml
type 'a lst = Nil | Cons of 'b
(* Unbound type parameter 'b *)
let add_one a = 1 + b
(* Unbound value b *)
```

Parameterised are everywhere, we've already seen that the polymorphic list is defined in such a way. But what about some projects using this useful language feature? [OMD](https://github.com/ocaml/omd) is an OCaml markdown parsing, html-generating tool and if we look at it's description of its abstract syntax tree we find that to describe a link it uses parameterised types (let's not get caught up in the module definition): 

```ocaml
module Link_def =
struct
  type 'a t =
    {
      label: 'a; (* The Label is Polymorphic - strings, ints etc. *)
      destination: string;
      title: string option;
      attributes: Attributes.t;
    }
end
```

# Polymorphic Variants

We've seen how variants can specify a set of constructors that some concept could be (vehicle type above). There is a parallel here with objects and the class hierarchy. 

# GADTs 

# The weirder types


