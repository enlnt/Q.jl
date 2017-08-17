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

k_name(x::Symbol) = Symbol(string("K_", x))
k_super(x::Symbol) = x == :Temporal ? AbstractTime : eval(x)

K_CLASSES = Type[]
# Create a parametrized type for each type class.
for c in TYPE_CLASSES
    name = k_name(c)
    super = k_super(c)
    @eval begin
        export $(name)
        mutable struct $(name){t,CT,JT} <: $(super)
            o::K_Object
            function $(name){t,CT,JT}(o::K_Object) where {t,CT,JT}
                t′ = xt(o.x)
                if t != -t′
                    throw(ArgumentError("type mismatch: t=$t, t′=$t′"))
                end
                new(o)
            end
            function $(name){t,CT,JT}(x::$(super)) where {t,CT,JT}
                o = K_Object(K_new(_cast(CT, x)))
                new(o)
            end
        end
        push!(K_CLASSES, $(name))
        # payload
        Base.eltype{t,CT,JT}(x::$(name){t,CT,JT}) = JT
        Base.pointer{t,CT,JT}(x::$(name){t,CT,JT}) = Ptr{CT}(x.o.x+8)
        load{t,CT,JT}(x::$(name){t,CT,JT}) = unsafe_load(pointer(x))
        store!{t,CT,JT}(x::$(name){t,CT,JT}, y::JT) = unsafe_store!(pointer(x), _cast(JT, y))
        function $(name)(o::K_Object)
            t = -xt(o.x)
            CT = C_TYPE[t]
            JT = JULIA_TYPE[t]
            $(name){t,CT,JT}(o)
        end
    end
end
K_CLASS = Dict{Int8,Type}()
# Aliases for concrete types.
for ti in TYPE_INFO
    name = k_name(ti.name)
    class = k_name(ti.class)
    @eval begin
        export $(name)
        global const $(name) =
              $(class){$(ti.number),$(ti.c_type),$(ti.jl_type)}
        function Base.convert(::Type{$(name)}, x::$(ti.jl_type))
            o = K_Object(ka($(ti.number)))
            r = $(name)(o)
            store!(r, x)
            r
        end
        K_CLASS[$(ti.number)] = $(class)
        Base.show(io::IO, ::Type{$(name)}) = print(io, $(string(name)))
        Base.convert(::Type{$(ti.jl_type)}, x::$(name)) = _cast($(ti.jl_type), load(x))
        Base.promote_rule(::Type{$(ti.jl_type)}, ::Type{$(name)}) = $(ti.jl_type)
    end
    if ti.class === :Signed || ti.class === :Integer
        @eval Base.dec(x::$(name), pad::Int=1) = string(dec(load(x), pad), $(ti.letter))
    elseif ti.class === :Unsigned
        @eval Base.hex(x::$(name), pad::Int=1, neg::Bool=false) = hex(load(x), pad, neg)
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
@eval const K = Union{K_Vector,K_Table,K_Other,$(K_CLASSES...)}
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
