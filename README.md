# Personal Website for 2020
---------------------------

** Status: Under Construction **

This personal website was built using the MirageOS library and largely inspired by [its website](https://mirage.io). This README acts as documentation for how it was built and so should hopefully help anyone else looking to get their feet wet with Mirage and Unikernels. 

What is a Unikernel? 
------
**TODO**

What is MirageOS?
------
**TODO**

*THE CONFIGURE FILE*
This is where a lot of the magic happens and there are a few key bits of terminology to remember and concepts to get your head around. 

### Keys 

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

### `@->` 

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



------

You made it to the end, here's why it's called [Lawrence](https://www.youtube.com/watch?v=Ou204dQbKwc). 