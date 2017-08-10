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
const C_TYPE = Dict(KB=>G_, UU=>UInt128, KG=>G_,
                    KH=>H_, KI=>I_, KJ=>J_,
                    KE=>E_, KF=>F_,
                    KC=>G_, KS=>S_,
                    KP=>J_, KM=>I_, KD=>I_,
                    KN=>J_, KU=>I_, KV=>I_, KT=>I_)
const JULIA_TYPE = Dict(KB=>Bool, UU=>UInt128, KG=>G_,
                    KH=>H_, KI=>I_, KJ=>J_,
                    KE=>E_, KF=>F_,
                    KC=>Char, KS=>Symbol,
                    KP=>J_, KM=>I_, KD=>I_,
                    KN=>J_, KU=>I_, KV=>I_, KT=>I_)

import Base.start, Base.next, Base.done, Base.length, Base.eltype
struct _State ptr; stop; stride::Int64 end
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

type K_Scalar{t,CT,JT}
    o::K_Object
    function K_Scalar{t,CT,JT}(o::K_Object) where {t,CT,JT}
        t′ = -xt(o.x)
        if(t != t′)
            throw(ArgumentError("type mismatch: t=$t, t′=$t′"))
        end
        return new{t,CT,JT}(o)
    end
end
function K_Scalar(o::K_Object)
    t = -xt(o.x)
    CT = C_TYPE[t]
    JT = JULIA_TYPE[t]
    K_Scalar{t,CT,JT}(o)
end
type K_Other
    o::K_Object
    function K_Other(o::K_Object)
        return new(o)
    end
end
type K_Vector{t,CT,JT} <: AbstractVector{JT}
    o::K_Object
    function K_Vector{t,CT,JT}(o::K_Object) where {t,CT,JT}
        t′ = xt(o.x)
        if(t != t′)
            throw(ArgumentError("type mismatch: t=$t, t′=$t′"))
        end
        return new{t,CT,JT}(o)
    end
end
K_Chars = K_Vector{KC,C_,Char}
function K_Vector(o::K_Object)
    t = xt(o.x)
    CT = C_TYPE[t]
    JT = JULIA_TYPE[t]
    K_Vector{t,CT,JT}(o)
end
_get{T}(::Type{T}, x::T) = x
_get{JT,CT}(::Type{JT}, x::CT) = JT(x)
_get(::Type{Symbol}, x::S_) = Symbol(unsafe_string(x))
K_Vector{T}(a::Vector{T}) = K_Vector(K(a))
Base.eltype{t,CT,JT}(v::K_Vector{t,CT,JT}) = JT
Base.size{t,CT,JT}(v::K_Vector{t,CT,JT}) = (xn(v.o.x),)
Base.getindex{t,CT,JT}(v::K_Vector{t,CT,JT}, i::Integer) =
    _get(JT, unsafe_load(Ptr{CT}(v.o.x + 16), i)::CT)
function Base.getindex(v::K_Chars, i::Integer)
    # XXX: Assumes ascii encoding
    n = xn(v.o.x)
    if (1 <= i <= n)
        return Char(unsafe_load(Ptr{C_}(v.o.x + 16), i))
    else
        throw(BoundsError(v, i))
    end
end
include("table.jl")
const K = Union{K_Scalar,K_Vector,K_Table,K_Other}

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
