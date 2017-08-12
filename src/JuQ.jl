module JuQ
export K, K_Vector, hopen, hclose, hget
include("k.jl")
using JuQ.k

#########################################################################
# Wrapper around q's C K type, with hooks to q reference
# counting and conversion routines to/from C and Julia types.
"""
    K_Object(x::K_)
A K object reference managed by Julia GC.
"""
type K_Object
    x::K_ # pointer to the actual K object
    function K_Object(x::K_)
        px = new(x)
        finalizer(px, (x->r0(x.x)))
        return px
    end
end

const JULIA_TYPE = Dict(KB=>Bool, UU=>UInt128, KG=>G_,
                    KH=>H_, KI=>I_, KJ=>J_,
                    KE=>E_, KF=>F_,
                    KC=>Char, KS=>Symbol,
                    KP=>J_, KM=>I_, KD=>I_,
                    KN=>J_, KU=>I_, KV=>I_, KT=>I_)


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

# K[...] constructors

Base.getindex(::Type{K}) = K(ktn(0,0))
function Base.getindex(::Type{K}, x)
    t = K_TYPE[typeof(x)]
    p = ktn(t, 1)
    K(p)
end
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
