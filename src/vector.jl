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
ktypecode(::K_Vector{t,C,T}) where {t,C,T} = t
const K_Chars = K_Vector{C_(10),G_,UInt8}
Base.convert(::Type{String}, x::K_Chars) = String(x.a)
Base.print(io::IO, x::K_Chars) = print(io, String(x))
Base.show(io::IO, x::K_Chars) = print(io, "K(", repr(String(x)), ")")
Base.show(io::IO, ::MIME"text/plain", x::K_Chars) = show(io, x)
Base.serialize(io::AbstractSerializer, x::K_Vector) =
    _serialize(io, x, typeof(x))
function K_Vector(x::K_)
    t = xt(x)
    ti = typeinfo(t)
    K_Vector{t,ti.c_type,ti.jl_type}(x)
end
const KnownLength = Union{Base.HasLength, Base.HasShape}
_vector(t::Integer, n::Integer) = K_Vector(ktn(t, n))
_vector(::Type{T}, n::Integer) where T = _vector(ktypecode(T), n)
_vector(t::Integer, itr, ::KnownLength) =
    (r = _vector(t, Int(length(itr)::Integer));copy!(r, itr);r)
K_Vector{t,C,T}(itr) where {t,C,T} =
    _vector(t, itr, Base.iteratorsize(itr))::K_Vector{t,C,T}
# XXX: Do we need this?
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

function resetvector(a::Vector, size::Integer, data::Ptr)
    p = Ptr{jl_array_t}(pointer_from_objref(a))
    # Pre-checks
    d = unsafe_load(p)
    @assert d.data == pointer(a)
    @assert d.length == d.nrows == length(a)
    # replant the data pointer
    unsafe_store!(Ptr{Ptr{Void}}(p), data)
    # update the size
    unsafe_store!(Ptr{Csize_t}(p + offset_length), size)
    unsafe_store!(Ptr{Csize_t}(p + offset_nrows), size)
    # Post-checks
    d = unsafe_load(p)
    @assert d.data == pointer(a)
    @assert d.length == d.nrows == length(a) == size
end

# ⚠️ Extending vectors
function Base.push!(x::K_Vector{t,C,T}, y) where {t,C,T}
    n′ = length(x) + 1
    a = _cast(C, T(y))
    p = kpointer(x)
    p′ = ja(Ref{K_}(p), Ref(a))
    resetvector(x.a, n′, p′+16)
    x
end
function Base.append!(x::K_Vector{t,C,T}, y::K_Vector{t,C,T}) where {t,C,T}
    n′ = length(x) + length(y)
    px = kpointer(x)
    py = kpointer(y)
    p′ = jv(Ref{K_}(px), py)
    resetvector(x.a, n′, p′+16)
    x
end
Base.append!(x::K_Vector{t,C,T}, y) where {t,C,T} =
    append!(x, K_Vector{t,C,T}(y))
function Base.empty!(x::K_Vector{t,C,T}) where {t,C,T}
    p = kpointer(x)
    p′ = ktn(t, 0)
    resetvector(x.a, 0, p′+16)
    r0(p)
    x
end
