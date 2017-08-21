# communications
hopen(host::String, port::Integer, user::String, timeout::Integer) =
    khpun(host, port, user, timeout)
hopen(host::String, port::Integer, user::String) = khpu(host, port, user)
hopen(host::String, port::Integer) = khp(host, port)
hopen(port::Integer) = hopen("localhost", port)
function hopen(;host="localhost", port=-1, user="", timeout=-1)
    if port == -1
        throw(ArgumentError("A port value must be specified"))
    end
    if timeout == -1
        if user == ""
            return khp(host, port)
        else
            return khpu(host, port, user)
        end
    else
        return khpun(host, port, user, timeout)
    end
end

function hopen(f::Function, host::String, port::Integer)
    h = hopen(host, port)
    try
        return f(h)
    finally
        kclose(h)
    end
end

hopen(f::Function, port::Integer) = hopen(f, "", port)

const hclose = kclose

hget(h::Integer, m::String) = K(k(h, m))
function hget(h::Integer, m::String, x...)
   r = k(h, m, map(K_, x)...)
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

# Initialise memory without making a connection
khp("", -1)
