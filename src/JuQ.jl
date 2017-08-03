module JuQ
export K, K_Vector, hopen, hclose, hget
include("k.jl")
using JuQ.k

#########################################################################
# Wrapper around q's C K type, with hooks to q reference
# counting and conversion routines to/from C and Julia types.
"""
    K_Object(x::K_Ptr)
A K object reference managed by Julia GC.
"""
type K_Object
    x::K_Ptr # pointer to the actual K object
    function K_Object(x::K_Ptr)
        px = new(x)
        finalizer(px, (x->r0(x.x)))
        return px
    end
end
const C_TYPE = Dict(KB=>G_, KG=>G_,
                    KH=>H_, KI=>I_, KJ=>J_,
                    KE=>E_, KF=>F_,
                    KC=>G_, KS=>S_,
                    KP=>J_, KM=>I_, KD=>I_,
                    KN=>J_, KU=>I_, KV=>I_, KT=>I_)
import Base.start, Base.next, Base.done, Base.length, Base.eltype
immutable _State ptr; stop; stride::Int64 end
eltype(x::K_Ptr) = C_TYPE[xt(x)]
function start(x::K_Ptr)
    t = eltype(x)
    ptr = Ptr{t}(x+16)
    stride = sizeof(t)
    stop = ptr + xn(x)*stride
    return _State(ptr, stop, stride)
end
next(x, s) = (unsafe_load(s.ptr), _State(s.ptr + s.stride, s.stop, s.stride))
done(x, s) = s.ptr == s.stop
length(x) = xn(x)

type K_Scalar{T}
    o::K_Object
    function K_Scalar{T}(o::K_Object) where T
        t = xt(o.x)
        if(-t != K_TYPE[T])
            throw(ArgumentError("type mismatch: t=$t, T=$T"))
        end
        return new{T}(o)
    end
end
K_Scalar(o::K_Object) = K_Scalar{C_TYPE[-xt(o.x)]}(o)
type K_Chars
    o::K_Object
    function K_Chars(o::K_Object)
        t = xt(o.x)
        if(t != KC)
            throw(ArgumentError("type mismatch: t=$t"))
        end
        return new(o)
    end
end
type K_Other
    o::K_Object
    function K_Other(o::K_Object)
        return new(o)
    end
end
type K_Vector{T} <: AbstractVector{T}
    o::K_Object
    function K_Vector{T}(o::K_Object) where T
        t = xt(o.x)
        if(t != K_TYPE[T])
            throw(ArgumentError("type mismatch: t=$t, T=$T"))
        end
        return new{T}(o)
    end
end
K_Vector(o::K_Object) = K_Vector{C_TYPE[xt(o.x)]}(o)
K_Vector{T}(a::Vector{T}) = K_Vector(K(a))
Base.eltype{T}(v::K_Vector{T}) = T
Base.size{T}(v::K_Vector{T}) = (xn(v.o.x),)
Base.getindex{T}(v::K_Vector{T}, i::Integer) =
    unsafe_load(Ptr{T}(v.o.x + 16), i)
function Base.getindex(v::K_Chars, i::Integer)
    # XXX: Assumes ascii encoding
    n = xn(v.o.x)
    if (1 <= i <= n)
        return Char(unsafe_load(Ptr{C_}(v.o.x + 16), i))
    else
        throw(BoundsError(v, i))
    end
end

include("conversions.jl")

# communications
hopen(h::String, p::Integer) = khp(h, p)
hclose = kclose

hget(h::Integer, m::String) = K_Object(k_(h, m))
function hget(h::Integer, m::String, x...)
   x = map(K, x)
   r = k_(h, m, map(x->x.o.x, x)...)
   return K(r)
end
function hget(h::Tuple{String,Integer}, m)
   h = hopen(h...)
   r = hget(h, m)
   kclose(h)
   return r
end
function hget(h::Tuple{String,Integer}, m, x...)
   h = hopen(h...)
   r = hget(h, m, x...)
   kclose(h)
   return r
end
end # module
