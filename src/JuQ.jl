module JuQ
export K, K_Atom, K_Vector, K_Table, hopen, hclose, hget
export KdbException

include("_k.jl")

"""
    K(x)

Construct a kdb+ object.
"""
abstract type K end
K(x) = convert(K, x)  # allow non-K return types
"""
    kpointer(x)

A memory address referring to a kdb+ object.
"""
kpointer

Base.convert(::Type{K_}, x) = r1(kpointer(x))
K_new(x) = r1(kpointer(x))

"""
    ktypecode(x)

Get the numeric type code of a `K` object.
"""
ktypecode(x) = ktypecode(typeof(x))

"""
    KdbException(s)

A call to kdb resulted in an error. Argument `s` is a descriptive error string
reported by kdb.
"""
struct KdbException <: Exception
    s::String
end

include("atom.jl")
include("vector.jl")

struct K_Lambda
    a::Vector{K_}
    K_Lambda(x::K_) = new(asarray(x))
end
struct K_Other
    a::Array{T,0} where T
    K_Other(x::K_) = new(asarray(x))
end
ktypecode(x::K_Other) = unsafe_load(kpointer(x)).t

include("table.jl")

for T in (K_symbol, K_char)
    @eval Base.:(==)(x::$T, y) = x[] == y
    @eval Base.:(==)(x, y::$T) = x == y[]
    @eval Base.:(==)(x::$T, y::$T) = x[] == y[]
end
Base.:(==)(x::T, y::T) where {T<:K_Atom} = x.a[] == y.a[]
Base.isless(x::K_Atom, y::K_Atom) = x.a[] < y.a[]

kpointer(x::Union{K_Atom,K_Other}) = K_(pointer(x.a)-8)
kpointer(x::Union{K_Vector,K_Lambda,K_guid}) = K_(pointer(x.a)-16)

#const K = Union{K_Atom,K_Vector,K_Table,K_Lambda,K_Other}
# TODO: Consider moving all K_new methods here.
K_new(x::K) = r1(kpointer(x))
const TI0 = TI(0, 'k', "any", K_, K, :NA)
typeinfo(t::Integer) = t == 0 ? TI0 : TYPE_INFO[t - (t>2)]

include("list.jl")

# Conversions between C and Julia types
_cast(::Type{T}, x::T) where T = x
_cast(::Type{T}, x::C) where {T,C} = T(x)
_cast(::Type{Symbol}, x::S_) = Symbol(unsafe_string(x))
_cast(::Type{K}, x::K_) = K(r1(x))
#_cast(::Type{K_}, x::K) = r1(kpointer(x))

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
