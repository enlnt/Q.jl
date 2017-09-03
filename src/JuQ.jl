module JuQ
export K, K_Object, K_Vector, K_Table, hopen, hclose, hget
export KdbException

include("_k.jl")
using Base.Dates.AbstractTime
using JuQ._k

"""
    KdbException(s)

A call to kdb resulted in an error. Argument `s` is a descriptive error string
reported by kdb.
"""
struct KdbException <: Exception
    s::String
end
# Supertypes for atomic q types.
const SUPERTYPE = Dict(
    :_Bool     => Integer,
    :_Unsigned => Unsigned,
    :_Signed   => Signed,
    :_Float    => AbstractFloat,
    :_Text     => Any,
    :_Temporal => AbstractTime
)
K_CLASSES = Type[]
# Create a parametrized type for each type class.
for (class, super) in SUPERTYPE
    @eval begin
        export $(class)
        struct $(class){t,CT,JT} <: $(super)
            a::Array{CT,0}
            function $(class){t,CT,JT}(x::K_) where {t,CT,JT}
                a = asarray(x)
                t′ = xt(x)
                if t != -t′
                    throw(ArgumentError("type mismatch: t=$t, t′=$t′"))
                end
                new(a)
            end
        end
        function Base.convert(::Type{$(class){t,C,T}}, x::C) where {t,C,T}
            r = $(class){t,C,T}(ka(-t))
            r.a[] = x
            r
        end
        function Base.convert(::Type{$(class){t,C,T}}, x) where {t,C,T}
            r = $(class){t,C,T}(ka(-t))
            r.a[] = _cast(C, T(x))::C
            r
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
        Base.eltype(::Type{$(class){t,C,T}}) where {t,C,T} = T
        Base.eltype(x::$(class)) = eltype(typeof(x))
        Base.getindex(x::$class) = eltype(x)(x)
        Base.pointer(x::$(class){t,CT,JT}) where {t,CT,JT} = pointer(x.a)
        Base.show(io::IO, x::$(class){t,CT,JT}) where {t,CT,JT} = print(io,
            "K(", repr(JT(x.a[])), ")")
    end
end
@eval const K_Scalar = Union{$(K_CLASSES...)}

K_CLASS = Dict{Int8,Type}()
# Aliases for concrete scalar types.
for ti in TYPE_INFO
    ktype = Symbol("K_", ti.name)
    class = ti.class
    T = ti.jl_type
    @eval begin
        export $(ktype)
        global const $(ktype) =
              $(class){$(ti.number),$(ti.c_type),$T}
        K_CLASS[$(ti.number)] = $(class)
        # Display type aliases by name in REPL.
        Base.show(io::IO, ::Type{$(ktype)}) = print(io, $(string(ktype)))
        # Conversion to Julia types
        Base.convert(::Type{$T}, x::$(ktype)) = _cast($T, x.a[])
        Base.promote_rule(x::Type{$T}, y::Type{$(ktype)}) = x
        # Disambiguate T -> K type conversions
        #Base.convert(::Type{$ktype}, x::$ktype) = x
    end
    if ti.class in [:_Signed, :_Integer]
        @eval Base.dec(x::$(ktype), pad::Int=1) =
            string(dec(x.a[], pad), $(ti.letter))
    elseif ti.class === :_Unsigned
        @eval Base.hex(x::$(ktype), pad::Int=1, neg::Bool=false) =
            hex(x.a[], pad, neg)
    end
end
function K_Scalar(x::K_)
    t = -xt(x)
    ti = typeinfo(t)
    K_CLASS[t]{t,ti.c_type,ti.jl_type}(x)
end
include("promote_rules.jl")
struct K_Lambda
    a::Vector{K_}
    K_Lambda(x::K_) = new(asarray(x))
end
struct K_Other
    a::Array{T,0} where T
    K_Other(x::K_) = new(asarray(x))
end
struct K_Vector{t,C,T} <: AbstractVector{T}
    a::Vector{C}
    function K_Vector{t,C,T}(x::K_) where {t,C,T}
        a = asarray(x)
        t′ = xt(x)
        if t != t′
            throw(ArgumentError("type mismatch: t=$t, t′=$t′"))
        end
        return new(a)
    end
end
const K_Chars = K_Vector{KC,C_,Char}
function K_Vector(x::K_)
    t = xt(x)
    ti = typeinfo(t)
    K_Vector{t,ti.c_type,ti.jl_type}(x)
end

Symbol(x::K_symbol) = convert(Symbol, x)
K_Vector(a::Vector) = K_Vector(K(a))

Base.eltype(v::K_Vector{t,C,T}) where {t,C,T} = T
Base.size(v::K_Vector{t,C,T}) where {t,C,T} = size(v.a)
Base.getindex(v::K_Vector{t,C,T}, i::Integer) where {t,C,T} = _cast(T, v.a[i])
# Setting the vector elements
Base.setindex!(v::K_Vector{t,C,T}, el, i::Integer) where {t,C,T} = begin
    v.a[i] = _cast(C, T(el))
    v
end

# See julia.h.
struct jl_array_t
    data   :: Ptr{Void} # (1)  sizeof(Ptr)
    length :: Csize_t   # (2) + sizeof(Ptr)
    flags  :: UInt16    # (3) + 2 bytes
    elsize :: UInt16    # (4) + 2 bytes
    offset :: UInt32    # (5) + 4 bytes
    nrows  :: Csize_t   # (6) = at 2*sizeof(Ptr) + 8
    maxsize:: Csize_t   # (7)
end

const offset_length = fieldoffset(jl_array_t, 2)
const offset_nrows = fieldoffset(jl_array_t, 6)
# Extending vectors (☡)
function Base.push!(x::K_Vector{t,C,T}, y) where {t,C,T}
    n′ = length(x) + 1
    a = _cast(C, T(y))
    p = K_(pointer(x)-16)
    p′ = ja(Ref{K_}(p), Ref(a))
    ptr_xa = Ptr{jl_array_t}(pointer_from_objref(x.a))
    # Pre-checks
    d = unsafe_load(ptr_xa)
    @assert d.data == pointer(x)
    @assert d.length == d.nrows == n′ - 1
    # replant the data pointer
    unsafe_store!(Ptr{Ptr{Void}}(ptr_xa), p′+16)
    # update the size
    unsafe_store!(Ptr{Csize_t}(ptr_xa + offset_length), n′)
    unsafe_store!(Ptr{Csize_t}(ptr_xa + offset_nrows), n′)
    # Post-checks
    d = unsafe_load(ptr_xa)
    @assert d.data == pointer(x)
    @assert d.length == d.nrows == n′
    x
end

include("table.jl")

for T in (K_symbol, K_char)
    @eval Base.:(==)(x::$T, y) = x[] == y
    @eval Base.:(==)(x, y::$T) = x == y[]
    @eval Base.:(==)(x::$T, y::$T) = x[] == y[]
end
Base.:(==)(x::T, y::T) where {T<:K_Scalar} = x.a[] == y.a[]
Base.isless(x::K_Scalar, y::K_Scalar) = x.a[] < y.a[]

kpointer(x::Union{K_Scalar,K_Other}) = K_(pointer(x.a)-8)
kpointer(x::Union{K_Vector,K_Lambda,K_guid}) = K_(pointer(x.a)-16)

const K = Union{K_Scalar,K_Vector,K_Table,K_Lambda,K_Other}
# TODO: Consider moving all K_new methods here.
_k.K_new(x::K) = r1(kpointer(x))
const TI0 = TI(0, 'k', "any", K_, K, :NA)
typeinfo(t::Integer) = t == 0 ? TI0 : TYPE_INFO[t - (t>2)]
# Conversions between C and Julia types
_cast(::Type{T}, x::T) where T = x
_cast(::Type{T}, x::C) where {T,C} = T(x)
_cast(::Type{Symbol}, x::S_) = Symbol(unsafe_string(x))
_cast(::Type{K}, x::K_) = K(r1(x))
_cast(::Type{K_}, x::K) = r1(kpointer(x))

# TODO: replace K_Vector with K below once asarray() transition is complete.
Base.pointer(x::K_Vector, i::Integer=1) = pointer(x.a, i)
Base.show(io::IO, ::Type{K}) = write(io, "K")

include("conversions.jl")

# K[...] constructors
Base.getindex(::Type{K}) = K(ktn(0,0))
function Base.getindex(::Type{K}, v)
    t = K_TYPE[typeof(v)]
    r = K(ktn(t, 1))
    r.a[1] = _cast(eltype(r), v)
    r
end
function Base.getindex(::Type{K}, v...)
    n = length(v)
    t = get(K_TYPE, Base.promote_typeof(v...), KK)
    r = K(ktn(t, n))
    C, T = map(eltype, (r.a, r))
    copy!(r.a, map(e->_cast(C, T(e)), v))
    r
end

if GOT_Q
    include("q.jl")
else
    include("communications.jl")
end
end # module JuQ
