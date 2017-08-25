module _k  # k.h wrappers
export k, okx, kclose
export ymd, dj
export r0, r1
export ktj, ka, kb, ku, kg, kh, ki, kj, ke, kf, sn, ss, ks, kc
export ja, js, jk
export ktn, knk, kp, xT, xD
export xa, xt, xr, xg, xh, xi, xj, xe, xf, xs, xn, xk, xx, xy
export C_, S_, G_, H_, I_, J_, E_, F_, V_, U_, K_, C_TYPE, K_TYPE
export KB, UU, KG, KH, KI, KJ, KE, KF, KC, KS, KP, KM, KD, KN, KU, KV, KT,
       XT, XD, KK, EE
export K_new
export TYPE_INFO, TYPE_CLASSES

include("startup.jl")

#########################################################################
# k.h
const C_ = Cchar
const S_ = Cstring
const G_ = Cuchar
const H_ = Cshort
const I_ = Cint
const J_ = Clonglong
const E_ = Cfloat
const F_ = Cdouble
const V_ = Void
const U_ = UInt128
struct k0
    m::C_
    a::C_
    t::C_  # type code
    u::C_
    r::I_  # reference count
end
const K_ = Ptr{k0}

TYPE_LETTERS = "kb  ghijefcspmdznuvt"
for (t, x) in enumerate(TYPE_LETTERS)
    isspace(x) || @eval const $(Symbol("K", uppercase(x))) = $(I_(t-1))
end
# guid
const UU = I_(2)
# table,dict
const XT = I_(98)   #   x->k is XD
const XD = I_(99)   #   kK(x)[0] is keys. kK(x)[1] is values.

const EE = I_(128)  #   error

Base.show(io::IO, ::Type{K_}) = write(io, "K_")

struct ∫
    number::C_
    letter::Char
    name::String
    c_type::Type
    jl_type::Type
    class::Symbol
end

const TYPE_INFO = [
    # num ltr name c_type jl_type super
    ∫(1, 'b', "boolean", G_, Bool, :_Bool),

    ∫(2, 'g', "guid", U_, UInt128, :_Unsigned),
    ∫(4, 'x', "byte", G_, UInt8, :_Unsigned),

    ∫(5, 'h', "short", H_, Int16, :_Signed),
    ∫(6, 'i', "int", I_, Int32, :_Signed),
    ∫(7, 'j', "long", J_, Int64, :_Signed),

    ∫(8, 'e', "real", E_, Float32, :_Float),
    ∫(9, 'f', "float", F_, Float64, :_Float),

    ∫(10, 'c', "char", C_, Char, :_Text),
    ∫(11, 's', "symbol", S_, Symbol, :_Text),

    ∫(12, 'p', "timestamp", J_, Int64, :_Temporal),
    ∫(13, 'm', "month", I_, Int32, :_Temporal),
    ∫(14, 'd', "date", I_, Int32, :_Temporal),
    ∫(15, 'z', "datetime", I_, Int32, :_Temporal),
    ∫(16, 'n', "timespan", J_, Int64, :_Temporal),
    ∫(17, 'u', "minute", I_, Int32, :_Temporal),
    ∫(18, 'v', "second", I_, Int32, :_Temporal),
    ∫(19, 't', "time", I_, Int32, :_Temporal),
]

const TYPE_CLASSES = unique(t.class for t in TYPE_INFO)
const C_TYPE = merge(
    Dict(KK=>K_, EE=>S_),
    Dict(t.number=>t.c_type for t in TYPE_INFO))
const K_TYPE = Dict(Bool=>KB, UInt128=>UU,
                    UInt8=>KG, Int16=>KH, Int32=>KI, Int64=>KJ,
                    Float32=>KE, Float64=>KF,
                    Char=>KC, Symbol=>KS, Cstring=>KS)
# reference management
r0(x::K_) = ccall((@k_sym :r0), K_, (K_,), x)
r1(x::K_) = ccall((@k_sym :r1), K_, (K_,), x)

# head accessors
xt(x::K_) = unsafe_load(x).t
xr(x::K_) = unsafe_load(x).r

# scalar accessors
xg(x::K_) = unsafe_load(Ptr{G_}(x+8))
xh(x::K_) = unsafe_load(Ptr{H_}(x+8))
xi(x::K_) = unsafe_load(Ptr{I_}(x+8))
xj(x::K_) = unsafe_load(Ptr{J_}(x+8))
xe(x::K_) = unsafe_load(Ptr{E_}(x+8))
xf(x::K_) = unsafe_load(Ptr{F_}(x+8))
xs(x::K_) = unsafe_string(unsafe_load(Ptr{S_}(x+8)))

# vector accessors
xn(x::K_) = unsafe_load(Ptr{J_}(x+8))
## XXX: These don't seem to be useful. Consider
# returning lighweight memory views.
# xG(x::K_) = Ptr{G_}(x+16)
# xH(x::K_) = Ptr{H_}(x+16)
# xI(x::K_) = Ptr{I_}(x+16)
# xJ(x::K_) = Ptr{J_}(x+16)
# xE(x::K_) = Ptr{E_}(x+16)
# xF(x::K_) = Ptr{F_}(x+16)

# table and dict accessors
xk(x::K_) = unsafe_load(Ptr{K_}(x+8))
xx(x::K_) = unsafe_load(Ptr{K_}(x+16), 1)
xy(x::K_) = unsafe_load(Ptr{K_}(x+16), 2)

# scalar constructors
ktj(t::Integer, x::Integer) = ccall((@k_sym :ktj), K_, (I_, J_), t, x)
kb(x::Integer) = ccall((@k_sym :kb), K_, (I_,), x)
ku(x::U_) = (p = ka(-UU); unsafe_store!(Ptr{U_}(p+8), x); p)
ku(x::Integer) = ku(U_(x))
kg(x::Integer) = ccall((@k_sym :kg), K_, (I_,), x)
ka(x::Integer) = ccall((@k_sym :ka), K_, (I_,), x)
kh(x::Integer) = ccall((@k_sym :kh), K_, (I_,), x)
ki(x::Integer) = ccall((@k_sym :ki), K_, (I_,), x)
kj(x::Integer) = ccall((@k_sym :kj), K_, (J_,), x)
ke(x::Real) = ccall((@k_sym :ke), K_, (F_,), x)
kf(x::Real) = ccall((@k_sym :kf), K_, (F_,), x)
kc(x::Integer) = ccall((@k_sym :kc), K_, (I_,), x)
const _AnyString = Union{String, Symbol, Cstring}
sn(x::_AnyString, n::Integer) = ccall((@k_sym :sn), S_, (S_,I_), x, n)
ss(x::_AnyString) = ccall((@k_sym :ss), S_, (S_,), x)
ks(x::_AnyString) = ccall((@k_sym :ks), K_, (S_,), x)

# vector constructors
kp(x::String) = ccall((@k_sym :kp), K_, (S_,), x)
ktn(t::Integer, n::Integer) = ccall((@k_sym :ktn), K_, (I_, J_), t, n)
#knk(n) = begin @assert n == 0; ccall((@k_sym :knk), K_, (I_,), 0) end
function knk(n::Integer, x::K_...)
    r = ktn(0, n)
    for i in 1:n
        unsafe_store!(Ptr{K_}(r+16), x[i], i)
    end
    return r
end
# table, dictionary
xT(x::K_) = ccall((@k_sym :xT), K_, (K_, ), x)
xD(x::K_, y::K_) = ccall((@k_sym :xD), K_, (K_, K_), x, y)

# ja(K*,V*),js(K*,S),jk(K*,K),jv(K*k,K)
ja(rx::Ref{K_}, y::Ref) = ccall((@k_sym :ja), K_, (Ref{K_}, Ptr{V_}), rx, y)
js(rx::Ref{K_}, y::S_) = ccall((@k_sym :js), K_, (Ref{K_}, S_), rx, y)
jk(rx::Ref{K_}, y::K_) = ccall((@k_sym :jk), K_, (Ref{K_}, K_), rx, y)

okx(x::K_) = ccall((@k_sym :okx), I_, (K_, ), x)
kclose(h::Integer) = ccall((@k_sym :kclose), V_, (I_, ), h)

# Dates
ymd(y::Integer, m::Integer, d::Integer) =
    ccall((@k_sym :ymd), I_, (I_, I_, I_), y, m, d)
dj(j::Integer) = ccall((@k_sym :dj), I_, (I_, ), j)

if GOT_Q
    export dot_, ee  # avoid conflict with Base.dot.
    dot_(x::K_, y::K_) = ccall((@k_sym :dot), K_, (K_, K_), x, y)
    ee(x::K_) = ccall((@k_sym :ee), K_, (K_, ), x)
else
    # communications (not included in q server)
    export khpun, khpu, khp
    # I khpun(const S,I,const S,I),khpu(const S,I,const S),khp(const S,I)
    khpun(h::String, p::Integer, u::String, n::Integer) =
        ccall((@k_sym :khpu), I_, (S_, I_, S_, I_), h, p, u, n)
    khpu(h::String, p::Integer, u::String) =
        ccall((@k_sym :khpu), I_, (S_, I_, S_), h, p, u)
    khp(h::String, p::Integer) = ccall((@k_sym :khp), I_, (S_, I_), h, p)
end

const K_NULL = K_(C_NULL)
# K k(I,const S,...)
# TODO: Use Julia metaprogramming to avoid repetition
k(h::Integer, m::String) =
    ccall((@k_sym :k), K_, (I_, S_, K_), h, m, K_NULL)
k(h::Integer, m::String, x1::K_) =
    ccall((@k_sym :k), K_, (I_, S_, K_, K_), h, m, x1, K_NULL)
k(h::Integer, m::String, x1::K_, x2::K_) =
    ccall((@k_sym :k), K_, (I_, S_, K_, K_, K_),
            h, m, x1, x2, K_NULL)
k(h::Integer, m::String, x1::K_, x2::K_, x3::K_) =
    ccall((@k_sym :k), K_, (I_, S_, K_, K_, K_, K_),
            h, m, x1, x2, x3, K_NULL)
k(h::Integer, m::String, x1::K_, x2::K_, x3::K_, x4::K_) =
    ccall((@k_sym :k), K_, (I_, S_, K_, K_, K_, K_, K_),
            h, m, x1, x2, x3, x4, K_NULL)
k(h::Integer, m::String, x1::K_, x2::K_, x3::K_, x4::K_, x5::K_) =
    ccall((@k_sym :k), K_, (I_, S_, K_, K_, K_, K_, K_, K_),
            h, m, x1, x2, x3, x4, x5, K_NULL)
k(h::Integer, m::String, x1::K_, x2::K_, x3::K_, x4::K_, x5::K_, x6::K_) =
    ccall((@k_sym :k), K_, (I_, S_, K_, K_, K_, K_, K_, K_, K_),
            h, m, x1, x2, x3, x4, x5, x6, K_NULL)
k(h::Integer, m::String, x1::K_, x2::K_, x3::K_, x4::K_, x5::K_, x6::K_,
    x7::K_) =
        ccall((@k_sym :k), K_, (I_, S_, K_, K_, K_, K_, K_, K_, K_, K_),
                h, m, x1, x2, x3, x4, x5, x6, x7, K_NULL)
k(h::Integer, m::String, x1::K_, x2::K_, x3::K_, x4::K_, x5::K_, x6::K_,
    x7::K_, x8::K_) =
        ccall((@k_sym :k), K_, (I_, S_, K_, K_, K_, K_, K_, K_, K_, K_, K_),
                h, m, x1, x2, x3, x4, x5, x6, x7, x8, K_NULL)
# Iterator protocol
import Base.start, Base.next, Base.done, Base.length, Base.eltype
struct _State{T} ptr::Ptr{T}; stop::Ptr{T}; stride::J_ end
eltype(x::K_) = C_TYPE[abs(xt(x))]
function start(x::K_)
    T = eltype(x)
    ptr = Ptr{T}(x+16)
    stride = sizeof(T)
    stop = ptr + xn(x)*stride
    return _State{T}(ptr, stop, stride)
end
next(x, s) = (unsafe_load(s.ptr), _State(s.ptr + s.stride, s.stop, s.stride))
done(x, s) = s.ptr == s.stop
length(x) = xn(x)

# Filling the elements
import Base.pointer, Base.fill!, Base.copy!
pointer(x::K_, i=1::Integer) = (T=eltype(x); Ptr{T}(x+15+i))
function fill!(x::K_, el)
    const n = xn(x)
    const p = pointer(x)
    const T = typeof(p).parameters[1]
    const f = (T === K_ ? r1 : identity)
    for i in 1:n
        unsafe_store!(p, T(f(el))::T, i)
    end
end
function copy!(x::K_, iter)
    const p = pointer(x)
    const T = typeof(p).parameters[1]
    const f = (T === K_ ? r1 : identity)
    for (i, el::T) in enumerate(iter)
        unsafe_store!(p, f(el), i)
    end
end

## New reference
K_new(x::K_) = r1(x)
## Conversion of simple types
K_new(x::Bool) = kb(x)
K_new(x::UInt128) = ku(x)
K_new(x::UInt8) = kg(x)
K_new(x::Int16) = kh(x)
K_new(x::Int32) = ki(x)
K_new(x::Int64) = kj(x)
K_new(x::Float32) = ke(x)
K_new(x::Float64) = kf(x)
K_new(x::Symbol) = ks(String(x))
K_new(x::Char) = kc(Int8(x))
K_new(x::String) = kp(x)
## Vector conversions
function K_new(a::Vector{T}) where {T<:Number}
    t = K_TYPE[T]
    CT = C_TYPE[t]
    n = length(a)
    x = ktn(t, n)
    unsafe_copy!(Ptr{T}(x+16), pointer(a), n)
    return x
end
function K_new(a::Vector{Symbol})
    t = KS
    CT = S_
    JT = Symbol
    n = length(a)
    x = ktn(t, n)
    for i in 1:n
        si = ss(a[i])
        unsafe_store!(Ptr{S_}(x+16), si, i)
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
end # module k
