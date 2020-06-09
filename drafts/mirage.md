# Lawrence
---------------------------

** Status: Under Construction **

How to run the server? 

```
cd src 
mirage configure -t <backend>
make depend 
make 
_build/main.native --http-port 4000
```

This personal website was built using the MirageOS library and largely inspired by [its website](https://mirage.io). This README acts as documentation for how it was built and so should hopefully help anyone else looking to get their feet wet with Mirage and Unikernels. 

What is a Unikernel? 
------
**TODO**

What is [MirageOS](https://mirage.io/)?
------

MirageOS is a library operating system. It allows you to build specific appliances for a particular purpose - *Unikernels*. A large number of applications exist today sitting on top of a large amount of code called the Operating System which handles networking, the filesystem etc. 

*THE CONFIGURE FILE*

This is where a lot of the magic happens and there are a few key bits of terminology to remember and concepts to get your head around. 



Modules and Functors
--------------------

In OCaml we have modules. Whenever you create a file, you are implicitly creating a module. One of the most useful things about modules is data abstraction and from this we get code reuse. A common idiom is to hide implementation details and this is often seen in a module as `type t`. Let's make a module for printable things. 

```ocaml
module type Printable = sig
  type t
  val print: t -> unit
end
```

This is the module signature and it allows us to instantiate modules which follow the signature. Below we instantiate a `String_printable` module which follow the `Printable` signature from above.

```ocaml
module String_printable : Printable = struct 
  type t = string 
  let print s = print_string s
end
```

What if we had a module which was a `Printable` but also could print lists of the abstract type. 

``` ocaml
module type Printable_list = sig
  include Printable 
  val print_list: t list -> unit
end
```

Now we just need a way to convert a `Printable` to a `Printable_list` - a functor. 

```ocaml
module Make_printable_list (P : Printable) : Printable_list = struct 
  type t = P.t
  let print s = P.print s
  let print_list xs = List.iter (fun x -> P.print x) xs
end

module String_list_printable = Make_printable_list (String_printable)
```

Keys 
-----

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

`@->` 
----

This symbol `@->` is defined in the `functoria.ml` [file](https://github.com/mirage/mirage/blob/master/functoria/lib/functoria.ml) - a domain-specific language (DSL) for working with functors. Functors, from what I understand, are like functions - only from module to module (or category to category?). Here are some of the important type signatures that help illuminate what is going on here. 

```ocaml
(* The typ type definition *)
type _ typ = Type: 'a -> 'a typ | Function: ('b typ * 'c typ) -> ('b * 'c) typ 

(* Just syntactic sugar... a @-> b @-> c = Function (a, Function (b, c)) *)
let (@->) f t = Function (f, t)

(* Foreign function takes the packages and keys as described above *)
(* The interesting part is the last argument of type `a typ *)
val foreign:
  ?packages:package list ->
  ?keys:key list ->
  ?deps:abstract_impl list ->
  string -> 'a typ -> 'a impl

(* Here we describe the function "Server.Run" which takes a http module and gives a job module*)
let main () = 
  foreign 
    ~keys
    "Server.Run" (http @-> job)
```

`$`
----

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

------

You made it to the end, here's why it's called [Lawrence](https://www.youtube.com/watch?v=Ou204dQbKwc). 