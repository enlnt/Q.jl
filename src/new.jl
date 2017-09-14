using Q._k

"""
    K_new(x)

Construct a new kdb+ object or create a new reference to an existing one. The
caller is reponsible for calling `r0` once the object is no longer needed.
"""
K_new

"""
    K_Ref(x)

Construct a Julia GC managed object that owns a kdb+ reference.
"""
mutable struct K_Ref
    x::K_
    K_Ref(p::K_) = (x = new(p); finalizer(x, (x)->r0(x.x));x)
end

struct TI
    number::C_
    letter::Char
    name::String
    c_type::Type
    jl_type::Type
    class::Symbol
end

const TYPE_INFO = [
    # num ltr name c_type jl_type super
    TI(1,  'b', "boolean",   B_, Bool,    :_Bool),

    TI(2,  'g', "guid",      U_, UInt128, :_Unsigned),
    TI(4,  'x', "byte",      G_, UInt8,   :_Unsigned),

    TI(5,  'h', "short",     H_, Int16,   :_Signed),
    TI(6,  'i', "int",       I_, Int32,   :_Signed),
    TI(7,  'j', "long",      J_, Int64,   :_Signed),

    TI(8,  'e', "real",      E_, Float32, :_Float),
    TI(9,  'f', "float",     F_, Float64, :_Float),

    TI(10, 'c', "char",      G_, UInt8,   :_Text),
    TI(11, 's', "symbol",    S_, Symbol,  :_Text),

    TI(12, 'p', "timestamp", J_, TimeStamp,   :_Time),
    TI(13, 'm', "month",     I_, Month,   :_Time),
    TI(14, 'd', "date",      I_, Date,    :_Time),
    TI(15, 'z', "datetime",  F_, DateTimeF, :_Time),
    TI(16, 'n', "timespan",  J_, TimeSpan,   :_Period),
    TI(17, 'u', "minute",    I_, Minute,   :_Time),
    TI(18, 'v', "second",    I_, Second,   :_Time),
    TI(19, 't', "time",      I_, Time,   :_Time),
]
const TYPE_CLASSES = unique(t.class for t in TYPE_INFO)
const C_TYPE = merge(
    Dict(KK=>K_, EE=>S_, XT=>K_, XD=>K_, (-EE)=>S_,  # XXX: do we need both ±EE?
         100=>K_, 101=>I_, 102=>I_, 103=>I_, 104=>K_, 105=>K_,
         106=>K_, 107=>K_, 108=>K_, 109=>K_, 110=>K_, 111=>K_, 112=>V_),
    Dict(t.number=>t.c_type for t in TYPE_INFO))

const K_TYPE = Dict(Bool=>KB, UInt128=>UU,
                    UInt8=>KG, Int16=>KH, Int32=>KI, Int64=>KJ,
                    Float32=>KE, Float64=>KF,
                    Char=>KC, Symbol=>KS, Cstring=>KS,
                    Date=>KD,)
# returns type, offset and size
function cinfo(x::K_)
    h = unsafe_load(x)
    t = h.t
    if t < 0   # scalar
        return C_TYPE[-t], (t == -UU ? 16 : 8), ()
    elseif t <= KT
        return C_TYPE[t], 16, (xn(x), )
    elseif t == XT
        return K_, 8, ()
    elseif t == XD
        return K_, 16, (2, )
    elseif t < 77
        return I_, 16, (xn(x), )
    elseif t < XT
        return J_, 16, (xn(x), )
    elseif t == 100  # λ
        return K_, 16, (xn(x), )
    elseif t < 104
        return I_, 8, ()
    elseif t < 106  # projection, composition
        return K_, 16, (xn(x), )
    elseif t < 112  # f', f/, f\, ...
        return K_, 8, ()
    else
        return Ptr{V_}, 16, ()
    end
end
## New reference
K_new(x::K_) = r1(x)
## Conversion of simple types
const _none = ktj(101, 0)
K_new(::Void) = r1(_none)
K_new(x::Bool) = kb(x)
K_new(x::UInt128) = ku(x)
K_new(x::UInt8) = kg(x)
K_new(x::Int16) = kh(x)
K_new(x::Int32) = ki(x)
K_new(x::Integer) = kj(x)
K_new(x::Float32) = ke(x)
K_new(x::Real) = kf(x)
K_new(x::Symbol) = ks(String(x))
K_new(x::Date) = kd(DATE_SHIFT + Dates.value(x))
K_new(x::DateTime) = ktj(-KP, 10^6*Dates.toms(x - DateTime(2000)))
K_new(x::Dates.TimePeriod) = ktj(-KN, Dates.tons(x))
K_new(x::Char) = kc(I_(x))
K_new(x::String) = kp(x)
## Vector conversions
function K_new(a::Vector{T}) where {T<:Number}
    t = K_TYPE[T]
    C = C_TYPE[t]
    n = length(a)
    x = ktn(t, n)
    unsafe_copy!(Ptr{C}(x+16), pointer(a), n)
    return x
end
function K_new(a::AbstractVector{T}) where {T<:Number}
    t = K_TYPE[T]
    C = C_TYPE[t]
    n = length(a)
    x = ktn(t, n)
    for i in 1:n
        unsafe_store!(Ptr{C}(x+16), C(a[i]), i)
    end
    return x
end
function K_new(a::AbstractVector{Symbol})
    t = KS
    n = length(a)
    x = ktn(t, n)
    for i in 1:n
        si = ss(a[i])
        unsafe_store!(Ptr{S_}(x+16), si, i)
    end
    return x
end
function K_new(a::AbstractVector{T}) where {T<:AbstractString}
    n = length(a)
    x = ktn(0, n)
    for i in 1:n
        si = kp(a[i])
        unsafe_store!(Ptr{K_}(x+16), si, i)
    end
    return x
end
function K_new(a::Union{Tuple,Vector{Any}})
    x = ktn(0, 0)
    r = Ref{K_}(x)
    for el in a
        jk(r, el isa K_ ? r1(el) : K_new(el))
    end
    r.x
end
# TODO: Add a fast specialization for the concrete Matrix type.
function K_new(m::AbstractMatrix)
    T = eltype(m)
    t = K_TYPE[T]
    C = C_TYPE[t]
    nrows, ncols = size(m)
    x = ktn(0, ncols)
    for j in 1:ncols
        pcol = kK(x)[j] = ktn(t, nrows)
        for i in 1:nrows
            kX(C, pcol)[i] = _cast(C, m[i,j])
        end
    end
    x
end

function K_new(df::AbstractDataFrame)
    x = K_new(names(df))
    y = ktn(0, xn(x))
    for (i, col) in enumerate(DataFrames.columns(df))
        kK(y)[i] = K_new(col)
    end
    xT(xD(x, y))
end

function asarray(x::K_, own::Bool=true)
    T, o, s = cinfo(x)
    a = unsafe_wrap(Array, Ptr{T}(x + o), s)
    if own
        finalizer(a, b->r0(K_(pointer(b)-o)))
    end
    a
end
# The _none pointer guard - make sure _none is cleaned up eventually.
const _none_array = asarray(_none)
# TODO: Consider using Array(x) instead of asarray(x).
# Base.convert(::Type{Array}, x::K_) = asarray(x)
