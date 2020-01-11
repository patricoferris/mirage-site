open Mirage 

(********* UNIKERNEL KEYS *********)
let http_port = 
  let doc = Key.Arg.info ~doc:"Port number for HTTP" ["http-port"] in
    Key.(create "http-port" Arg.(opt ~stage:`Both int 80 doc))

let https_port =
  let doc = Key.Arg.info ~doc:"Port number for HTTPS" ~docv:"PORT" ["https-port"] in
    Key.(create "https-port" Arg.(opt ~stage:`Both int 443 doc))

let fs_key = 
  Key.(value @@ kv_ro ())

let host_key =
  let doc = Key.Arg.info
      ~doc:"Hostname of the unikernel."
      ~docv:"URL" ~env:"HOST" ["host"]
  in
  Key.(create "host" Arg.(opt string "localhost" doc))

let keys = Key.([abstract http_port; abstract https_port; abstract host_key])
let packages = [ package "cohttp-mirage"; package "re2" ]
(********* Setting up implementations *********)
let stack = generic_stackv4 default_network
let filesfs = generic_kv_ro ~key:fs_key "../files"

(******** MAIN FUNCTIONS *********)
let http =
  foreign
    ~keys
    ~packages
    "Server.Run" (http @-> kv_ro @-> job)

let () =
  register "run" [(http $ cohttp_server (conduit_direct stack)) $ filesfs]