# communications
hopen(h::String, p::Integer) = khp(h, p)
hclose = kclose

hget(h::Integer, m::String) = K(k_(h, m))
function hget(h::Integer, m::String, x...)
   r = k_(h, m, map(K_, x)...)
   return K(r)
end
function hget(h::Tuple{String,Integer}, m)
   h = hopen(h...)
   try
       return hget(h, m)
   finally
       kclose(h)
   end
end
function hget(h::Tuple{String,Integer}, m, x...)
   h = hopen(h...)
   try
       return hget(h, m, x...)
   finally
       kclose(h)
   end
end
