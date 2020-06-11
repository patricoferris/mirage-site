---
authors: 
  - Patrick Ferris 
title: MirageOS
updated: 2020-01-22
tags:
  - unikernels
  - ocaml 
---

*This post assumes some knowledge of the [OCaml](https://ocaml.org/) programming language and an understanding of computer systems like operating systems. [This](http://pages.cs.wisc.edu/~remzi/OSTEP/) is a great website for learning more about OSes.*

## What is a MirageOS? 

MirageOS is a *library* operating system. It uses the library paradigm to provide a high-level, modular way to build operating systems. It allows you to build specific applications for a particular purpose - *unikernels*. 

A large number of applications exist today sitting on top of a large amount of code called the operating system (OS) which handles things like networking and the filesystem (memory). As an example think about running a *Node.js* application - you need some host OS to install the *Node.js* runtime on and then you write your programs to run in that runtime.

One of the problems with this approach is security, your small webserver suddenly relies on a whole operating system to run! With MirageOS this doesn't need to be the case. You define what parts of the OS you want and it can run on top of a hypervisor. 

A hypervisor, sometimes called a Virtual Machine Monitor (VMM), carves up a physical machines resources allowing multiple *virtual* machines to exist concurrently. A virtual machine is an isolated execution environment and any OS running inside it is called a *guest operating system*. Hypervisors tend to be much smaller than full OSes, exposing few priveleged functions reducing the potential for security holes. 


## How MirageOS works
 
What follows are some of the key concepts which make up MirageOS. 

### Modules and Functors

Functional programming in OCaml is largely managed by a powerful module system. All code in OCaml is wrapped up inside of a module. When you write a `hello.ml` file you have implicityly created a `Hello` module. 

Signatures or interfaces for modules are like structural contracts to the bare minimum an implementation should provide. For example: 

```ocaml
module Bool : sig
  type t 
  val tru : t 
  val fls : t
  val ifthenelse : t -> 'a -> 'a -> 'a
end = struct 
  type t = True | False 
  let tru = True
  let fls = False
  let ifthenelse b e1 e2 = match b with 
    | True  -> e1
    | False -> e2
end;;

Bool.(ifthenelse fls 1 0) (* Returns 0 *)
```
The user can't interact with the implementation, the type `t` for `Bool` remains abstract. This is generally desirable as it minimises the chances of other developers misusing or breaking implementations. 

The true power of the module system comes from its composability. Functors are what functions are to terms for modules. Let's say we wanted to make a list that was always sorted. Provided the elements of the list were comparable in some way, we can do this. 

```ocaml 
module type Printable = sig 
  type t 
  val print : t -> unit
end 

module Animals = struct 
  type t = Camel | Other 
  let print = function 
    | Camel -> print_string "🐫🐫🐫" 
    | Other -> print_string "not a camel" 
end 

module Make (P : Printable) : sig
  include Printable
  val print_list : P.t list -> unit 
end = struct 
  type t = P.t 
  let print t = P.print t 
  let print_list lst = List.iter P.print lst 
end 

module AnimalList = Make(Animals)
```

We know have a list printing function for elements of type `Animal.t`. 

```ocaml
AnimalList.print_list (Animals.([Camel, Other]))
```

What this tries to show through a very contrived example is that functors enable abstraction. We could build a list printing function from the abstract notion of something that could print elements. In MirageOS this is slightly more complicated, but the principle is similar. Allow the user to work with abstract notions of common OS building-blocks and fill in the implementation details later dependent on the backend being targeted. 

## Functoria

Managing functors and modules in such a complex way is tricky. The solution was to build a domain-specific language (DSL) to help manage the complexity whilst being readable and usable. This is Functoria.

### `@->` 

This symbol `@->` is defined in the `functoria.ml` [file](https://github.com/mirage/mirage/blob/master/functoria/lib/functoria.ml). Here are some of the important type signatures that help illuminate what is going on here. 

```ocaml
(* typ types represent module signatures *)
type _ t =
  | Type : 'a -> 'a t (* module type *)
  | Function : 'a t * 'b t -> ('a -> 'b) t

(* Just syntactic sugar: a @-> b @-> c = Function (a, Function (b, c)) *)
let ( @-> ) f x = Function (f, x)
```

Functoria represents modules and functors using types. A value of type `('a -> 'b) typ` is a functor from a module signature described by `'a` to one described by `b`. Unikernels, in the Mirage sense, are just functors. 

If we look at the ["Hello World"](https://github.com/mirage/mirage-skeleton/blob/master/tutorial/hello/config.ml) Mirage example, we can see `(time @-> job)` is given to the `foreign` function. This describes the unikernel. The unikernel needs some notion of time (in this example to be able to sleep), so the unikernel signature is a functor with a time argument. We get the value `time` from the [mirage types](https://github.com/mirage/mirage/blob/master/lib/mirage/mirage_impl_time.mli) definition. 

The `foreign` function is just an alias for the `DSL.main` function which has the following type: 

```ocaml
val main :
  ?packages:package list ->
  ?packages_v:package list Key.value ->
  ?keys:abstract_key list ->
  ?extra_deps:Impl.abstract list ->
  string ->
  'a typ ->
  'a impl
```

The optional arguments are fairly straightforward, the `packages` are the dependencies which are installed before compilation. The `string` argument is the name of the unikernel and the `'a typ` is the module signture type. From this we can see the job is to produce a module implementation type from the signature.

### `$`

The `$` operator is again just more syntactic sugar - it applies functors and modules. So in the code below `http $ cohttp_server (conduit_direct stack)` is applying the `http` functor to the module you get by taking the `cohttp_server` function and applying the `(conduit_direct stack)` conduit implementation. 

```ocaml
type _ impl =
    | Impl: 'ty Typ.configurable -> 'ty impl (* base implementation *)
    | App: ('a, 'b) app -> 'b impl           (* functor application *)
    | If: bool Key.value * 'a impl * 'a impl -> 'a impl

let ($) f x = App { f; x }

let () =
  register "run" [(http $ cohttp_server (conduit_direct stack)) $ filesfs]

```


### Keys 

These are **configuration keys** - typically when we are building programs we pass additional information into the program to be used at runtime. Think `gcc -o test.out test.c`. But for a Unikernel there is no notion of a command-line, instead we use keys. To construct a key we can use the `create` function. 

```ocaml
val create: string -> 'a Arg.t -> 'a key
```

The `string` is the name of the command-line argument and the argument can be passed in using `Arg.(opt <stage> <type> <default> <documentation>)`. Something that has been added here is the port number for the connection. The `<stage>` argument specifies whether argument is taken at configuration, runtime or both. 

```ocaml
let http_port = 
  let doc = Key.Arg.info ~doc:"Port number for HTTP" ["port"] in
    Key.(create "port" Arg.(opt ~stage:`Both int 8080 doc))
```