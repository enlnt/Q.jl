module k  # k.h wrappers
export k_, khpun, khpu, khp, okx, kclose
export ymd, dj
export r0, r1
export ktj, ka, kb, kg, kh, ki, kj, ke, kf, sn, ss, ks, kc
export ktn, knk, kp, xT, xD
export xa, xt, xr, xg, xh, xi, xj, xf, xs, xn, xk, xx, xy
export C_, S_, G_, H_, I_, J_, E_, F_, V_, U_, K_, C_TYPE, K_TYPE
export KB, UU, KG, KH, KI, KJ, KE, KF, KC, KS, KP, KM, KD, KN, KU, KV, KT,
       XT, XD, KK
export @k_sym

const SYS_CHAR = Dict(
    :Linux => 'l',
    :Darwin => 'm',
)
const SYS_ARCH = @sprintf("%c%d", SYS_CHAR[Sys.KERNEL], Sys.WORD_SIZE)
const C_SO_PATH = joinpath(dirname(@__FILE__), SYS_ARCH, "c")
const C_SO = Libdl.dlopen(C_SO_PATH,
            Libdl.RTLD_LAZY|Libdl.RTLD_DEEPBIND|Libdl.RTLD_GLOBAL)

macro k_sym(func)
    :(($(esc(func)), C_SO_PATH))
end

#########################################################################
# k.h
TYPE_LETTERS = "kb  ghijefcspmdznuvt"
for (t, x) in enumerate(TYPE_LETTERS)
    isspace(x) || @eval const $(Symbol("K", uppercase(x))) = $(Int8(t-1))
end
# guid
const UU = Int8(2)
# table,dict
const XT = Int8(98) #   x->k is XD
const XD = Int8(99) #   kK(x)[0] is keys. kK(x)[1] is values.

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
Base.show(io::IO, ::Type{K_}) = write(io, "K_")

const C_TYPE = Dict(KK=>K_, KB=>G_, UU=>U_, KG=>G_,
                    KH=>H_, KI=>I_, KJ=>J_,
                    KE=>E_, KF=>F_,
                    KC=>G_, KS=>S_,
                    KP=>J_, KM=>I_, KD=>I_,
                    KN=>J_, KU=>I_, KV=>I_, KT=>I_)
const K_TYPE = Dict(Bool=>KB,
                    UInt8=>KG, Int16=>KH, Int32=>KI, Int64=>KJ,
                    Float32=>KE, Float64=>KF,
                    Char=>KC, Symbol=>KS, Cstring=>KS)
# reference management
r0(x::K_) = ccall((@k_sym :r0), K_, (K_,), x)
r1(x::K_) = ccall((@k_sym :r1), K_, (K_,), x)

# head accessors
xa(x::K_) = unsafe_load(x).a
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
xG(x::K_) = Ptr{G_}(x+16)
xH(x::K_) = Ptr{H_}(x+16)
xI(x::K_) = Ptr{I_}(x+16)
xJ(x::K_) = Ptr{J_}(x+16)
xE(x::K_) = Ptr{E_}(x+16)
xF(x::K_) = Ptr{F_}(x+16)

# table and dict accessors
xk(x::K_) = unsafe_load(Ptr{K_}(x+8))
xx(x::K_) = unsafe_load(Ptr{K_}(x+16), 1)
xy(x::K_) = unsafe_load(Ptr{K_}(x+16), 2)


# scalar constructors
ktj(t::Integer, x::Integer) = ccall((@k_sym :ktj), K_, (I_, J_), t, x)
kb(x::Integer) = ccall((@k_sym :kb), K_, (I_,), x)
kg(x::Integer) = ccall((@k_sym :kg), K_, (I_,), x)
ka(x::Integer) = ccall((@k_sym :ka), K_, (I_,), x)
kh(x::Integer) = ccall((@k_sym :kh), K_, (I_,), x)
ki(x::Integer) = ccall((@k_sym :ki), K_, (I_,), x)
kj(x::Integer) = ccall((@k_sym :kj), K_, (J_,), x)
ke(x::Real) = ccall((@k_sym :ke), K_, (F_,), x)
kf(x::Real) = ccall((@k_sym :kf), K_, (F_,), x)
kc(x::Integer) = ccall((@k_sym :kc), K_, (I_,), x)
sn(x::String, n::Integer) = ccall((@k_sym :sn), S_, (S_,I_), x, n)
ss(x::String) = ccall((@k_sym :ss), S_, (S_,), x)
ss(x::Symbol) = ccall((@k_sym :ss), S_, (S_,), x)
ks(x::String) = ccall((@k_sym :ks), K_, (S_,), x)

# vector constructors
kp(x::String) = ccall((@k_sym :kp), K_, (S_,), x)
ktn(t::Integer, n::J_) = ccall((@k_sym :ktn), K_, (I_, J_), t, n)
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

# communications
# extern I khpun(const S,I,const S,I),khpu(const S,I,const S),khp(const S,I),okx(K),
khpun(h::String, p::Integer, u::String, n::Integer) =
    ccall((@k_sym :khpu), I_, (S_, I_, S_, I_), h, p, u, n)
khpu(h::String, p::Integer, u::String) =
    ccall((@k_sym :khpu), I_, (S_, I_, S_), h, p, u)
khp(h::String, p::Integer) = ccall((@k_sym :khp), I_, (S_, I_), h, p)
okx(x::K_) = ccall((@k_sym :okx), I_, (K_, ), x)
kclose(h::Integer) = ccall((@k_sym :kclose), V_, (I_, ), h)

# Dates
ymd(y::Integer, m::Integer, d::Integer) =
    ccall((@k_sym :ymd), I_, (I_, I_, I_), y, m, d)
dj(j::Integer) = ccall((@k_sym :dj), I_, (I_, ), j)

# K k(I,const S,...)
k_(h::Integer, m::String) =
    ccall((@k_sym :k), K_, (I_, S_, K_), h, m, K_(C_NULL))
k_(h::Integer, m::String, x::K_...) =
    ccall((@k_sym :k), K_, (I_, S_, K_...), h, m, x..., K_(C_NULL))

# Iterator protocol
import Base.start, Base.next, Base.done, Base.length, Base.eltype
struct _State{T} ptr::Ptr{T}; stop::Ptr{T}; stride::J_ end
eltype(x::K_) = C_TYPE[xt(x)]
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
        unsafe_store!(p, f(el::T), i)
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

# Low level conversions
## Conversions of simple types
Base.convert(::Type{K_}, x::Bool) = kb(x)
# TODO: guid
Base.convert(::Type{K_}, x::UInt8) = kg(x)
Base.convert(::Type{K_}, x::Int16) = kh(x)
Base.convert(::Type{K_}, x::Int32) = ki(x)
Base.convert(::Type{K_}, x::Int64) = kj(x)
Base.convert(::Type{K_}, x::Float32) = ke(x)
Base.convert(::Type{K_}, x::Float64) = kf(x)
Base.convert(::Type{K_}, x::Symbol) = ks(String(x))
Base.convert(::Type{K_}, x::Char) = kc(Int8(x))
Base.convert(::Type{K_}, x::String) = kp(x)
## Vector conversions
function Base.convert(::Type{K_}, a::Vector{T}) where {T<:Number}
    t = K_TYPE[T]
    CT = C_TYPE[t]
    n = length(a)
    x = ktn(t, n)
    unsafe_copy!(Ptr{T}(x+16), pointer(a), n)
    return x
end
function Base.convert(::Type{K_}, a::Vector{Symbol})
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
end # module k
