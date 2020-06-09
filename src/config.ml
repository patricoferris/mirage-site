open Mirage 

(********* UNIKERNEL KEYS *********)
let http_port = 
  let doc = Key.Arg.info ~doc:"Port number for HTTP" ["http-port"] in
    Key.(create "http-port" Arg.(opt ~stage:`Both int 80 doc))

let https_port =
  let doc = Key.Arg.info ~doc:"Port number for HTTPS" ~docv:"PORT" ["https-port"] in
    Key.(create "https-port" Arg.(opt ~stage:`Both int 443 doc))

let git_remote = 
  let doc = Key.Arg.info ~doc:"Git remote URI" ["git-remote"] in 
    Key.(create "git-remote" Arg.(opt ~stage:`Both string "git://github.com/patricoferris/mirage-site.git" doc))

let fs_key = 
  Key.(value @@ kv_ro ())

let host_key =
  let doc = Key.Arg.info
      ~doc:"Hostname of the unikernel."
      ~docv:"URL" ~env:"HOST" ["host"]
  in
  Key.(create "host" Arg.(opt string "localhost" doc))

let keys = Key.([ abstract host_key; abstract http_port; abstract https_port; abstract git_remote])
let packages = [ 
  package "tyxml-ppx";
  package "tyxml";
  package "cohttp-mirage"; 
  package "irmin-mirage-git";
  package "yaml";
  package "omd";
  package "fpath";
  package "duration";
  package "ptime";
  package ~min:"2.0.0" "mirage-kv";
]

(********* Setting up implementations *********)
let stack = generic_stackv4 default_network 
let cond = conduit_direct stack 
let resolver = resolver_dns stack
let filesfs = generic_kv_ro ~key:fs_key "../static"

(******** MAIN FUNCTIONS *********)
let http =
  foreign
    ~keys
    ~packages
    "Server.Make" (http @-> kv_ro @-> Mirage.resolver @-> Mirage.conduit @-> pclock @-> job)

let () =
  let conduit = cohttp_server @@ conduit_direct stack in  
  register "run" [http $ conduit $ filesfs $ resolver $ cond $ default_posix_clock]