type ('a, 'b) t = {
  cache: ('a, 'b) Hashtbl.t;
  capacity: int;
  mutable size: int;
}

let create cap = {
  cache = Hashtbl.create cap; 
  capacity = cap;
  size = 0;
}

let flush cache = 
  Hashtbl.clear cache.cache; cache.size <- 0

let put cache key value = 
  if cache.size = cache.capacity then flush cache;
  Hashtbl.add cache.cache key value; cache.size <- cache.size + 1

let find cache key = 
  Hashtbl.find_opt cache.cache key