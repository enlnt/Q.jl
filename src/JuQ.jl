module JuQ
export K, K_Object, K_Vector, K_Table, hopen, hclose, hget
include("k.jl")
using Base.Dates.AbstractTime
using JuQ.k

#########################################################################
# Wrapper around q's C K type, with hooks to q reference
# counting and conversion routines to/from C and Julia types.
"""
    K_Object(x::K_)
A K object reference managed by Julia GC.
"""
mutable struct K_Object
    x::K_ # pointer to the actual K object
    function K_Object(x::K_)
        px = new(x)
        finalizer(px, (o->(x = o.x;x == C_NULL || r0(x))))
        return px
    end
end
const SUPERTYPE = Dict(
    :_Bool=>Integer,
    :_Unsigned=>Unsigned,
    :_Signed=>Signed,
    :_Float=>AbstractFloat,
    :_Text=>Any,
    :_Temporal=>AbstractTime
)
K_CLASSES = Type[]
# Create a parametrized type for each type class.
for (class, super) in SUPERTYPE
    @eval begin
        export $(class)
        mutable struct $(class){t,CT,JT} <: $(super)
            o::K_Object
            function $(class){t,CT,JT}(o::K_Object) where {t,CT,JT}
                t′ = xt(o.x)
                if t != -t′
                    throw(ArgumentError("type mismatch: t=$t, t′=$t′"))
                end
                new(o)
            end
            function $(class){t,CT,JT}(x::$(super)) where {t,CT,JT}
                o = K_Object(K_new(_cast(CT, x)))
                new(o)
            end
        end
        push!(K_CLASSES, $(class))
        Base.size(::$(class)) = ()
        Base.size(x::$(class), d) =
            convert(Int, d) < 1 ? throw(BoundsError()) : 1
        Base.ndims(x::$(class)) = 0
        Base.ndims(x::Type{$(class)}) = 0
        Base.length(x::$(class)) = 1
        Base.endof(x::$(class)) = 1
        # payload
        Base.eltype{t,CT,JT}(x::$(class){t,CT,JT}) = JT
        Base.pointer{t,CT,JT}(x::$(class){t,CT,JT}) = Ptr{CT}(x.o.x+8)
        load{t,CT,JT}(x::$(class){t,CT,JT}) = unsafe_load(pointer(x))
        store!{t,CT,JT}(x::$(class){t,CT,JT}, y::JT) = unsafe_store!(pointer(x), _cast(JT, y))
        function $(class)(o::K_Object)
            t = -xt(o.x)
            CT = C_TYPE[t]
            JT = JULIA_TYPE[t]
            $(class){t,CT,JT}(o)
        end
    end
end
K_CLASS = Dict{Int8,Type}()
# Aliases for concrete scalar types.
for ti in TYPE_INFO
    ktype = Symbol("K_", ti.name)
    class = ti.class
    @eval begin
        export $(ktype)
        global const $(ktype) =
              $(class){$(ti.number),$(ti.c_type),$(ti.jl_type)}
        function Base.convert(::Type{$(ktype)}, x::$(ti.jl_type))
            o = K_Object(ka($(ti.number)))
            r = $(ktype)(o)
            store!(r, x)
            r
        end
        K_CLASS[$(ti.number)] = $(class)
        Base.show(io::IO, ::Type{$(ktype)}) = print(io, $(string(ktype)))
        Base.convert(::Type{$(ti.jl_type)}, x::$(ktype)) = _cast($(ti.jl_type), load(x))
        Base.promote_rule(::Type{$(ti.jl_type)}, ::Type{$(ktype)}) = $(ti.jl_type)
    end
    if ti.class in [:_Signed, :_Integer]
        @eval Base.dec(x::$(ktype), pad::Int=1) = string(dec(load(x), pad), $(ti.letter))
    elseif ti.class === :_Unsigned
        @eval Base.hex(x::$(ktype), pad::Int=1, neg::Bool=false) = hex(load(x), pad, neg)
    end
end
include("promote_rules.jl")
mutable struct K_Other
    o::K_Object
    function K_Other(o::K_Object)
        return new(o)
    end
end
mutable struct K_Vector{t,CT,JT} <: AbstractVector{JT}
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
_cast{T}(::Type{T}, x::T) = x
_cast{JT,CT}(::Type{JT}, x::CT) = JT(x)
_cast(::Type{Symbol}, x::S_) = Symbol(unsafe_string(x))
Symbol(x::K_symbol) = convert(Symbol, x)
K_Vector{T}(a::Vector{T}) = K_Vector(K(a))
Base.eltype{t,CT,JT}(v::K_Vector{t,CT,JT}) = JT
Base.size{t,CT,JT}(v::K_Vector{t,CT,JT}) = (xn(v.o.x),)
Base.getindex{t,CT,JT}(v::K_Vector{t,CT,JT}, i::Integer) =
    _cast(JT, unsafe_load(Ptr{CT}(v.o.x + 16), i)::CT)
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
@eval const K_Scalar = Union{$(K_CLASSES...)}
Base.:(==)(x::K_Scalar, y::K_Scalar) = load(x) == load(y)
Base.isless(x::K_Scalar, y::K_Scalar) = load(x) < load(y)
const K = Union{K_Vector,K_Table,K_Other,K_Scalar}
Base.show(io::IO, ::Type{K}) = write(io, "K")
_cast(::Type{K}, x::K_) = K(x == C_NULL ? x : r1(x))
_cast(::Type{K_}, x::K) = (x = x.o.x; x == C_NULL ? x : r1(x))

const JULIA_TYPE = merge(
    Dict(KK=>K),
    Dict(ti.number=>ti.jl_type for ti in TYPE_INFO))

include("conversions.jl")

# Setting the vector elements
import Base.pointer, Base.fill!, Base.copy!, Base.setindex!
pointer{t,CT,JT}(x::K_Vector{t,CT,JT}, i::Integer=1) = Ptr{CT}(x.o.x+15+i)
function fill!{t,CT,JT}(x::K_Vector{t,CT,JT}, el::JT)
    const n = xn(x.o.x)
    const p = pointer(x)
    el = _cast(CT, el)
    for i in 1:n
        unsafe_store!(p, el, i)
    end
end
function copy!{t,CT,JT}(x::K_Vector{t,CT,JT}, iter)
    const p = pointer(x)
    for (i, el::JT) in enumerate(iter)
        el = _cast(CT, el)
        unsafe_store!(p, el, i)
    end
end
function setindex!{t,CT,JT}(x::K_Vector{t,CT,JT}, el::JT, i::Int)
    const p = pointer(x)
    el = _cast(CT, el)
    unsafe_store!(p, el, i)
end

# K[...] constructors

Base.getindex(::Type{K}) = K(ktn(0,0))
function Base.getindex(::Type{K}, v)
    const t = K_TYPE[typeof(v)]
    const x = ktn(t, 1)
    const T = eltype(x)
    v = _cast(T, v)
    copy!(x, [v])
    K(x)
end
function Base.getindex(::Type{K}, v...)
    const n = length(v)
    v = promote(v...)
    u = unique(map(typeof, v))
    if length(u) == 1 && (const t = get(K_TYPE, u[1], KK)) > KK
        const x = ktn(t, n)
        const T = eltype(x)
        v = map(e->_cast(T, e), collect(v))
        copy!(x, v)
    else
        const x = ktn(0, n)
        copy!(x, map(K_, v))
    end
    K(x)
end
include("communications.jl")
if GOT_Q
    include("q.jl")
end
end # module JuQ
