
module Wrapper = struct   
  let t ~title ~headers ~content = 
    let body = Cowabloga.Foundation.body ~title ~headers ~content ~trailers:[] () in 
    let body = Cowabloga.Foundation.page ~body in 
      Lwt.return (`Html (Lwt.return body))
end 

module Home = struct 
  let t ~title ~headers ~content ~read:_ ~domain =
    let body =
      Cowabloga.Foundation.body ~title ~headers ~content ~trailers:[] ()
    in
    let body = Cowabloga.Foundation.page ~body in
    Lwt.return (`Html (Lwt.return body))
end 