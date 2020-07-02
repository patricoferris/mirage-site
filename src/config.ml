open Mirage 

(********* UNIKERNEL KEYS *********)
let https_port =
  let doc = Key.Arg.info ~doc:"Port number for HTTPS" ~docv:"PORT" ["https-port"] in
    Key.(create "https-port" Arg.(opt ~stage:`Both int 443 doc))

let git_remote = 
  let doc = Key.Arg.info ~doc:"Git remote URI" ["git-remote"] in 
    Key.(create "git-remote" Arg.(opt ~stage:`Both string "https://github.com/patricoferris/mirage-site.git" doc))

let tls_key = 
  Key.(value @@ kv_ro ~group:"certs" ())

let host_key =
  let doc = Key.Arg.info
      ~doc:"Hostname of the unikernel."
      ~docv:"URL" ~env:"HOST" ["host"]
  in
  Key.(create "host" Arg.(opt string "localhost" doc))

(* OAuth *)
let client_id =
  let doc = Key.Arg.info ~doc:"OAuth Client Id" ["client-id"] in 
    Key.(create "client-id" Arg.(opt ~stage:`Both string "abc" doc))

let client_secret = 
  let doc = Key.Arg.info ~doc:"OAuth Client Secret" ["client-secret"] in 
    Key.(create "client-secret" Arg.(opt ~stage:`Both string "123" doc))

let keys = Key.([ abstract host_key; abstract https_port; abstract git_remote; abstract client_id; abstract client_secret])
let packages = [ 
  package "tyxml-ppx";
  package "tyxml";
  package "cohttp-mirage"; 
  package "irmin-git";
  package "irmin-mirage-git";
  package "yaml";
  package "yojson";
  package "omd";
  package "fpath";
  package "duration";
  package "ptime";
  package ~min:"2.0.0" "mirage-kv";
]

(********* Setting up implementations *********)
let stack = generic_stackv4 default_network 
let cond = conduit_direct ~tls:true stack 
let resolver = resolver_dns stack
let secrets = generic_kv_ro ~key:tls_key "../secrets"

(******** MAIN FUNCTIONS *********)
let http =
  foreign
    ~keys
    ~packages
    "Server.Make" (http @-> kv_ro @-> Mirage.resolver @-> Mirage.conduit @-> pclock @-> job)

let () =
  register "run" [http $ (cohttp_server @@ conduit_direct ~tls:true stack) $ secrets $ resolver $ cond $ default_posix_clock]
