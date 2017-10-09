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
export ktj, ka, kb, ku, kg, kh, ki, kj, ke, kf, sn, ss, ks, kc, kd, kz, kt
export ja, js, jk, jv
export ktn, knk, kp, xT, xD
export xa, xt, t, xr, r, xg, xh, xi, xj, xe, xf, xs, xn, xp, n, xk, xx, xy
export kG, kH, kI, kJ, kE, kF, kC, kS, kK, kX
export B_, C_, S_, G_, H_, I_, J_, E_, F_, V_, U_, K_
export KB, UU, KG, KH, KI, KJ, KE, KF, KC, KS, KP, KM, KD, KZ, KN, KU, KV, KT,
       XT, XD, KK, EE

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
xs(x::K_) = (s = unsafe_load(Ptr{S_}(x+8)); s == C_NULL?"null":unsafe_string(s))

# vector accessors
const xn = n(x::K_) = unsafe_load(Ptr{J_}(x+8))
xp(x::K_) = unsafe_string(Ptr{UInt8}(x+16), xn(x))

kG(x::K_) = unsafe_wrap(Array, Ptr{G_}(x+16), (x|>n,))
kH(x::K_) = unsafe_wrap(Array, Ptr{H_}(x+16), (x|>n,))
kI(x::K_) = unsafe_wrap(Array, Ptr{I_}(x+16), (x|>n,))
kJ(x::K_) = unsafe_wrap(Array, Ptr{J_}(x+16), (x|>n,))
kE(x::K_) = unsafe_wrap(Array, Ptr{E_}(x+16), (x|>n,))
kF(x::K_) = unsafe_wrap(Array, Ptr{F_}(x+16), (x|>n,))
kC(x::K_) = unsafe_wrap(Array, Ptr{C_}(x+16), (x|>n,))
kS(x::K_) = unsafe_wrap(Array, Ptr{S_}(x+16), (x|>n,))
kK(x::K_) = unsafe_wrap(Array, Ptr{K_}(x+16), (x|>n,))
# Not in k.h, but useful
kX(::Type{C}, x::K_) where {C} = unsafe_wrap(Array, Ptr{C}(x+16), (x|>n,))

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
kc(x::Char) = kc(UInt8(x))
const _AnyString = Union{String, Symbol, Cstring}
"Intern n chars from a string"
sn(x::_AnyString, n::Integer) = ccall((@k_sym :sn), S_, (S_,I_), x, n)
"Intern a string"
ss(x::_AnyString) = ccall((@k_sym :ss), S_, (S_,), x)
"Create a symbol"
ks(x::_AnyString) = ccall((@k_sym :ks), K_, (S_,), x)
"Create a date"
kd(x::Integer) = ccall((@k_sym :kd), K_, (I_,), x)
"Create a datetime (deprecated)"
kz(x::AbstractFloat) = ccall((@k_sym :kz), K_, (F_,), x)
"Create a time"
kt(x::Integer) = ccall((@k_sym :kt), K_, (I_,), x)

# vector constructors
"Create a char array from string"
kp(x::AbstractString) = ccall((@k_sym :kp), K_, (S_,), x)
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
"Join a K_ object to a list"
jk(rx::Ref{K_}, y::K_) = ccall((@k_sym :jk), K_, (Ref{K_}, K_), rx, y)
"Join another K_ list to a list"
jv(rx::Ref{K_}, y::K_) = ccall((@k_sym :jv), K_, (Ref{K_}, K_), rx, y)

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
    export dot_, #= avoid conflict with Base.dot. =# ee, dl, khp
    export krr, orr
    dot_(x::K_, y::K_) = ccall((@k_sym :dot), K_, (K_, K_), x, y)
    ee(x::K_) = ccall((@k_sym :ee), K_, (K_, ), x)
    # dl(V*f,I)
    dl(f::Ptr{V_}, n::Integer) = ccall((@k_sym :dl), K_, (Ptr{V_}, I_), f, n)
    # Simulate khp with hopen
    function khp(h::String, p::Integer)
        x = k(0, "hopen", ks(string(":", h, ":", p)))
        try
            return xi(x)
        finally
            r0(x)
        end
    end
    krr(x::AbstractString) = ccall((@k_sym :krr), K_, (S_, ), x)
    orr(x::AbstractString) = ccall((@k_sym :orr), K_, (S_, ), x)
else
    # communications (not included in q server)
    export khpun, khpu, khp, krr, orr
    # I khpun(const S,I,const S,I),khpu(const S,I,const S),khp(const S,I)
    khpun(h::String, p::Integer, u::String, n::Integer) = ccall((@k_sym :khpu),
        I_, (S_, I_, S_, I_), h, p, u, n)
    khpu(h::String, p::Integer, u::String) = ccall((@k_sym :khpu),
        I_, (S_, I_, S_), h, p, u)
    khp(h::String, p::Integer) = ccall((@k_sym :khp), I_, (S_, I_), h, p)
    function krr(x::AbstractString)
        e = ka(-128)
        unsafe_store!(Ptr{S_}(e+8), ss(x))
        e
    end
    orr(x::AbstractString) = krr(String(x, ": ", Libc.strerror()))
end

const K_NULL = K_(C_NULL)
# K k(I,const S,...)
# TODO: Use Julia metaprogramming to avoid repetition
k(h::Integer, m::String) = ccall((@k_sym :k), K_, (I_, S_, K_), h, m, K_NULL)
k(h::Integer, m::String, x1::K_) = ccall((@k_sym :k),
    K_, (I_, S_, K_, K_), h, m, x1, K_NULL)
k(h::Integer, m::String, x1::K_, x2::K_) = ccall((@k_sym :k),
    K_, (I_, S_, K_, K_, K_), h, m, x1, x2, K_NULL)
k(h::Integer, m::String, x1::K_, x2::K_, x3::K_) = ccall((@k_sym :k),
    K_, (I_, S_, K_, K_, K_, K_), h, m, x1, x2, x3, K_NULL)
k(h::Integer, m::String, x1::K_, x2::K_, x3::K_, x4::K_) = ccall((@k_sym :k),
    K_, (I_, S_, K_, K_, K_, K_, K_), h, m, x1, x2, x3, x4, K_NULL)
k(h::Integer, m::String,
    x1::K_, x2::K_, x3::K_, x4::K_, x5::K_) = ccall((@k_sym :k),
        K_, (I_, S_, K_, K_, K_, K_, K_, K_), h, m, x1, x2, x3, x4, x5, K_NULL)
k(h::Integer, m::String,
    x1::K_, x2::K_, x3::K_, x4::K_, x5::K_, x6::K_) = ccall((@k_sym :k),
        K_, (I_, S_, K_, K_, K_, K_, K_, K_, K_),
            h, m, x1, x2, x3, x4, x5, x6, K_NULL)
k(h::Integer, m::String,
    x1::K_, x2::K_, x3::K_, x4::K_, x5::K_, x6::K_, x7::K_) = ccall((@k_sym :k),
        K_, (I_, S_, K_, K_, K_, K_, K_, K_, K_, K_),
            h, m, x1, x2, x3, x4, x5, x6, x7, K_NULL)
k(h::Integer, m::String,
    x1::K_, x2::K_, x3::K_, x4::K_, x5::K_, x6::K_,
        x7::K_, x8::K_) = ccall((@k_sym :k),
            K_, (I_, S_, K_, K_, K_, K_, K_, K_, K_, K_, K_),
                h, m, x1, x2, x3, x4, x5, x6, x7, x8, K_NULL)
# Make sure we don't redefine basic pointer conversions.
using Core.Intrinsics.bitcast
Base.convert(::Type{K_}, p::K_) = p
Base.convert(::Type{K_}, p::Ptr) = bitcast(K_, p)
Base.convert(::Type{K_}, p::UInt) = bitcast(K_, p)
end # module k
