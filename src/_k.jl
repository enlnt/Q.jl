"""
Kx Systems provides C API that can be used both on the server side (calling
functions defined in the q binary) or on the server side by linking with a
`c.o` object file.  With a few exceptions, the same functions are available
on the server and the client side and they are declared in a C header `k.h`.

This module is a thin wrapper for the kdb+ C API.
"""
module _k  # k.h wrappers
export k, b9, d9, okx, kclose
export ymd, dj
export r0, r1
export ktj, ka, kb, ku, kg, kh, ki, kj, ke, kf, sn, ss, ks, kc
export ja, js, jk
export ktn, knk, kp, xT, xD
export xa, xt, t, xr, r, xg, xh, xi, xj, xe, xf, xs, xn, n, xk, xx, xy
export kG, kH, kI, kJ, kE, kF, kC, kS, kK
export B_, C_, S_, G_, H_, I_, J_, E_, F_, V_, U_, K_, C_TYPE, K_TYPE
export KB, UU, KG, KH, KI, KJ, KE, KF, KC, KS, KP, KM, KD, KN, KU, KV, KT,
       XT, XD, KK, EE
export K_new
export TYPE_INFO, TYPE_CLASSES, TI
export asarray

include("startup.jl")

#########################################################################
# k.h
const B_ = Bool  # not in k.h
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
    TI(1, 'b', "boolean", B_, Bool, :_Bool),

    TI(2, 'g', "guid", U_, UInt128, :_Unsigned),
    TI(4, 'x', "byte", G_, UInt8, :_Unsigned),

    TI(5, 'h', "short", H_, Int16, :_Signed),
    TI(6, 'i', "int", I_, Int32, :_Signed),
    TI(7, 'j', "long", J_, Int64, :_Signed),

    TI(8, 'e', "real", E_, Float32, :_Float),
    TI(9, 'f', "float", F_, Float64, :_Float),

    TI(10, 'c', "char", C_, Char, :_Text),
    TI(11, 's', "symbol", S_, Symbol, :_Text),

    TI(12, 'p', "timestamp", J_, Int64, :_Temporal),
    TI(13, 'm', "month", I_, Int32, :_Temporal),
    TI(14, 'd', "date", I_, Int32, :_Temporal),
    TI(15, 'z', "datetime", I_, Int32, :_Temporal),
    TI(16, 'n', "timespan", J_, Int64, :_Temporal),
    TI(17, 'u', "minute", I_, Int32, :_Temporal),
    TI(18, 'v', "second", I_, Int32, :_Temporal),
    TI(19, 't', "time", I_, Int32, :_Temporal),
]
const TYPE_CLASSES = unique(t.class for t in TYPE_INFO)
const C_TYPE = merge(
    Dict(KK=>K_, EE=>S_, XT=>K_, XD=>K_, (-EE)=>S_,  # XXX: do we need both ±EE?
         100=>K_, 101=>I_, 102=>I_, 103=>I_, 104=>K_, 105=>K_,
         106=>K_, 107=>K_, 108=>K_, 109=>K_, 110=>K_, 111=>K_, 112=>V_),
    Dict(t.number=>t.c_type for t in TYPE_INFO))
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
const K_TYPE = Dict(Bool=>KB, UInt128=>UU,
                    UInt8=>KG, Int16=>KH, Int32=>KI, Int64=>KJ,
                    Float32=>KE, Float64=>KF,
                    Char=>KC, Symbol=>KS, Cstring=>KS)
# reference management
"Increment the object's reference count"
r0(x::K_) = ccall((@k_sym :r0), K_, (K_,), x)
"Decrement the object's reference count"
r1(x::K_) = ccall((@k_sym :r1), K_, (K_,), x)

# head accessors
const xt = t(x::K_) = unsafe_load(x).t
const xr = r(x::K_) = unsafe_load(x).r

# scalar accessors
xg(x::K_) = unsafe_load(Ptr{G_}(x+8))
xh(x::K_) = unsafe_load(Ptr{H_}(x+8))
xi(x::K_) = unsafe_load(Ptr{I_}(x+8))
xj(x::K_) = unsafe_load(Ptr{J_}(x+8))
xe(x::K_) = unsafe_load(Ptr{E_}(x+8))
xf(x::K_) = unsafe_load(Ptr{F_}(x+8))
xs(x::K_) = unsafe_string(unsafe_load(Ptr{S_}(x+8)))

# vector accessors
const xn = n(x::K_) = unsafe_load(Ptr{J_}(x+8))

kG(x::K_) = unsafe_wrap(Array, Ptr{G_}(x+16), (x|>n,))
kH(x::K_) = unsafe_wrap(Array, Ptr{H_}(x+16), (x|>n,))
kI(x::K_) = unsafe_wrap(Array, Ptr{I_}(x+16), (x|>n,))
kJ(x::K_) = unsafe_wrap(Array, Ptr{J_}(x+16), (x|>n,))
kE(x::K_) = unsafe_wrap(Array, Ptr{E_}(x+16), (x|>n,))
kF(x::K_) = unsafe_wrap(Array, Ptr{F_}(x+16), (x|>n,))
kC(x::K_) = unsafe_wrap(Array, Ptr{C_}(x+16), (x|>n,))
kS(x::K_) = unsafe_wrap(Array, Ptr{S_}(x+16), (x|>n,))
kK(x::K_) = unsafe_wrap(Array, Ptr{K_}(x+16), (x|>n,))

# table and dict accessors
xk(x::K_) = unsafe_load(Ptr{K_}(x+8))
xx(x::K_) = unsafe_load(Ptr{K_}(x+16), 1)
xy(x::K_) = unsafe_load(Ptr{K_}(x+16), 2)

# scalar constructors
"Create an atom of type and value"
ktj(t::Integer, x::Integer) = ccall((@k_sym :ktj), K_, (I_, J_), t, x)
"Create an atom of type"
ka(x::Integer) = ccall((@k_sym :ka), K_, (I_,), x)
"Create a boolean"
kb(x::Integer) = ccall((@k_sym :kb), K_, (I_,), x)
"Create a guid"
ku(x::U_) = (p = ka(-UU); unsafe_store!(Ptr{U_}(p+16), x); p)
ku(x::Integer) = ku(U_(x))
"Create a byte"
kg(x::Integer) = ccall((@k_sym :kg), K_, (I_,), x)
"Create a short"
kh(x::Integer) = ccall((@k_sym :kh), K_, (I_,), x)
"Create an int"
ki(x::Integer) = ccall((@k_sym :ki), K_, (I_,), x)
"Create a long"
kj(x::Integer) = ccall((@k_sym :kj), K_, (J_,), x)
"Create a real"
ke(x::Real) = ccall((@k_sym :ke), K_, (F_,), x)
"Create a float"
kf(x::Real) = ccall((@k_sym :kf), K_, (F_,), x)
"Create a char"
kc(x::Integer) = ccall((@k_sym :kc), K_, (I_,), x)
const _AnyString = Union{String, Symbol, Cstring}
"Intern n chars from a string"
sn(x::_AnyString, n::Integer) = ccall((@k_sym :sn), S_, (S_,I_), x, n)
"Intern a string"
ss(x::_AnyString) = ccall((@k_sym :ss), S_, (S_,), x)
"Create a symbol"
ks(x::_AnyString) = ccall((@k_sym :ks), K_, (S_,), x)

# vector constructors
"Create a char array from string"
kp(x::String) = ccall((@k_sym :kp), K_, (S_,), x)
"Create a simple list of type and length"
ktn(t::Integer, n::Integer) = ccall((@k_sym :ktn), K_, (I_, J_), t, n)
#knk(n) = begin @assert n == 0; ccall((@k_sym :knk), K_, (I_,), 0) end
"Create a mixed list of length"
function knk(n::Integer, x::K_...)
    r = ktn(0, n)
    for i in 1:n
        unsafe_store!(Ptr{K_}(r+16), x[i], i)
    end
    return r
end
# table, dictionary
"Create a table from a dict"
xT(x::K_) = ccall((@k_sym :xT), K_, (K_, ), x)
"Create a dict"
xD(x::K_, y::K_) = ccall((@k_sym :xD), K_, (K_, K_), x, y)

# ja(K*,V*),js(K*,S),jk(K*,K),jv(K*k,K)
"Join an atom to a list"
ja(rx::Ref{K_}, y::Ref) = ccall((@k_sym :ja), K_, (Ref{K_}, Ptr{V_}), rx, y)
"Join a symbol to a list"
js(rx::Ref{K_}, y::S_) = ccall((@k_sym :js), K_, (Ref{K_}, S_), rx, y)
"Join another K_ object to a list"
jk(rx::Ref{K_}, y::K_) = ccall((@k_sym :jk), K_, (Ref{K_}, K_), rx, y)

# K b9(I,K) and K d9(K)
b9(pe::Integer, x::K_) = ccall((@k_sym :b9), K_, (I_, K_), pe, x)
d9(x::K_) = ccall((@k_sym :d9), K_, (K_, ), x)
okx(x::K_) = ccall((@k_sym :okx), I_, (K_, ), x)
kclose(h::Integer) = ccall((@k_sym :kclose), V_, (I_, ), h)

# Dates
"Encode a year/month/day as q date"
ymd(y::Integer, m::Integer, d::Integer) = ccall((@k_sym :ymd),
    I_, (I_, I_, I_), y, m, d)
"Convert q date to yyyymmdd integer"
dj(j::Integer) = ccall((@k_sym :dj), I_, (I_, ), j)

if GOT_Q
    export dot_, ee  # avoid conflict with Base.dot.
    dot_(x::K_, y::K_) = ccall((@k_sym :dot), K_, (K_, K_), x, y)
    ee(x::K_) = ccall((@k_sym :ee), K_, (K_, ), x)
else
    # communications (not included in q server)
    export khpun, khpu, khp
    # I khpun(const S,I,const S,I),khpu(const S,I,const S),khp(const S,I)
    khpun(h::String, p::Integer, u::String, n::Integer) = ccall((@k_sym :khpu),
        I_, (S_, I_, S_, I_), h, p, u, n)
    khpu(h::String, p::Integer, u::String) = ccall((@k_sym :khpu),
        I_, (S_, I_, S_), h, p, u)
    khp(h::String, p::Integer) = ccall((@k_sym :khp), I_, (S_, I_), h, p)
end

const K_NULL = K_(C_NULL)
# K k(I,const S,...)
# TODO: Use Julia metaprogramming to avoid repetition
k(h::Integer, m::String) = ccall((@k_sym :k), K_, (I_, S_, K_), h, m, K_NULL)
k(h::Integer, m::String, x1::K_) = ccall((@k_sym :k),
    K_, (I_, S_, K_, K_), h, m, x1, K_NULL)
k(h::Integer, m::String, x1::K_, x2::K_) = ccall((@k_sym :k),
    K_, (I_, S_, K_, K_, K_), h, m, x1, x2, K_NULL)
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

## New reference
K_new(x::K_) = r1(x)
## Conversion of simple types
K_new(::Void) = ktj(101, 0)
K_new(x::Bool) = kb(x)
K_new(x::UInt128) = ku(x)
K_new(x::UInt8) = kg(x)
K_new(x::Int16) = kh(x)
K_new(x::Int32) = ki(x)
K_new(x::Int64) = kj(x)
K_new(x::Float32) = ke(x)
K_new(x::Float64) = kf(x)
K_new(x::Symbol) = ks(String(x))
K_new(x::Char) = kc(I_(x))
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

function asarray(x::K_, own::Bool=true)
    T, o, s = cinfo(x)
    a = unsafe_wrap(Array, Ptr{T}(x + o), s)
    if own
        finalizer(a, b->r0(K_(pointer(b)-o)))
    end
    a
end


end # module k
