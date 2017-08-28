module JuQ
export K, K_Object, K_Vector, K_Table, hopen, hclose, hget
export KdbException

include("_k.jl")
using Base.Dates.AbstractTime
using JuQ._k

struct KdbException <: Exception
    s::String
end

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
            function $(class){t,CT,JT}(x::K_) where {t,CT,JT}
                o = K_Object(x)
                t′ = xt(x)
                if t != -t′
                    throw(ArgumentError("type mismatch: t=$t, t′=$t′"))
                end
                new(o)
            end
        end
        function Base.convert(::Type{$(class){t,CT,JT}}, x) where {t,CT,JT}
            p = ka(-t)
            unsafe_store!(Ptr{CT}(p+8), _cast(CT, JT(x))::CT)
            $(class){t,CT,JT}(p)
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
        Base.eltype(x::$(class){t,CT,JT}) where {t,CT,JT} = JT
        Base.pointer(x::$(class){t,CT,JT}) where {t,CT,JT} = Ptr{CT}(x.o.x+8)
        load(x::$(class){t,CT,JT}) where {t,CT,JT} = unsafe_load(pointer(x))
        _get(x::$(class){t,CT,JT}) where {t,CT,JT} = _cast(JT, load(x))
        store!(x::$(class){t,CT,JT}, y::CT) where {t,CT,JT} =
            (unsafe_store!(pointer(x), y); x)
        _set!(x::$(class){t,CT,JT}, y) where {t,CT,JT} =
            (store!(x, _cast(CT, convert(JT, y))); x)
        Base.show(io::IO, x::$class) = print(io, "K(", repr(_get(x)), ")")
    end
end
@eval const K_Scalar = Union{$(K_CLASSES...)}

K_CLASS = Dict{Int8,Type}()
# Aliases for concrete scalar types.
for ti in TYPE_INFO
    ktype = Symbol("K_", ti.name)
    class = ti.class
    @eval begin
        export $(ktype)
        global const $(ktype) =
              $(class){$(ti.number),$(ti.c_type),$(ti.jl_type)}
        K_CLASS[$(ti.number)] = $(class)
        # Display type aliases by name in REPL.
        Base.show(io::IO, ::Type{$(ktype)}) = print(io, $(string(ktype)))
        # Conversion to Julia types
        Base.convert(::Type{$(ti.jl_type)}, x::$(ktype)) = _get(x)
        Base.promote_rule(x::Type{$(ti.jl_type)},
                          y::Type{$(ktype)}) = x
        # Disambiguate T -> K type conversions
        Base.convert(::Type{$ktype}, x::$ktype) = x
        # Display and printing
    end
    if ti.class in [:_Signed, :_Integer]
        @eval Base.dec(x::$(ktype), pad::Int=1) =
            string(dec(load(x), pad), $(ti.letter))
    elseif ti.class === :_Unsigned
        @eval Base.hex(x::$(ktype), pad::Int=1, neg::Bool=false) =
            hex(load(x), pad, neg)
    end
end
function K_Scalar(x::K_)
    t = -xt(x)
    ti = typeinfo(t)
    class = K_CLASS[t]
    return class{t,ti.c_type,ti.jl_type}(x)
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
_cast(::Type{T}, x::T) where T = x
_cast(::Type{JT}, x::CT) where {JT,CT} = JT(x)
_cast(::Type{Symbol}, x::S_) = Symbol(unsafe_string(x))

Symbol(x::K_symbol) = convert(Symbol, x)
K_Vector(a::Vector) = K_Vector(K(a))

Base.eltype(v::K_Vector{t,CT,JT}) where {t,CT,JT} = JT
Base.size(v::K_Vector{t,CT,JT}) where {t,CT,JT} = (convert(Int, xn(v.o.x)),)
function Base.getindex(v::K_Vector{t,CT,JT}, i::Integer) where {t,CT,JT}
    @boundscheck checkbounds(v, i)
    _cast(JT, unsafe_load(Ptr{CT}(v.o.x + 16), i)::CT)
end
include("table.jl")

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
pointer(x::K_Vector{t,CT,JT}, i::Integer=1) where {t,CT,JT} =
    Ptr{CT}(x.o.x+15+i)
function fill!(x::K_Vector{t,CT,JT}, el::JT) where {t,CT,JT}
    n = xn(x.o.x)
    p = pointer(x)
    el = _cast(CT, el)
    for i in 1:n
        unsafe_store!(p, el, i)
    end
    x
end
function setindex!(x::K_Vector{t,CT,JT}, el, i::Int) where {t,CT,JT}
    @boundscheck checkbounds(x, i)
    p = pointer(x)
    el = _cast(CT, convert(JT, el)::JT)
    unsafe_store!(p, el, i)
    x
end

# K[...] constructors

Base.getindex(::Type{K}) = K(ktn(0,0))
function Base.getindex(::Type{K}, v)
    t = K_TYPE[typeof(v)]
    x = ktn(t, 1)
    T = eltype(x)
    v = _cast(T, v)
    copy!(x, [v])
    K(x)
end
function Base.getindex(::Type{K}, v...)
    n = length(v)
    v = promote(v...)
    u = unique(map(typeof, v))
    if length(u) == 1 && (t = get(K_TYPE, u[1], KK)) > KK
        x = ktn(t, n)
        T = eltype(x)
        v = map(e->_cast(T, e), collect(v))
        copy!(x, v)
    else
        x = ktn(0, n)
        copy!(x, map(K_, v))
    end
    K(x)
end

function Base.push!(x::K_Vector{t,C,T}, y) where {t,C,T}
    a = _cast(C, T(y))
    ja(Ref{K_}(x.o.x), Ref{C}(a))
    x
end

if GOT_Q
    include("q.jl")
else
    include("communications.jl")
end
end # module JuQ
