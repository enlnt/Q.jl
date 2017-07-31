module JuQ
export K, K_Vector, hopen, hclose, hget
module k
export k_, khp, kclose
export r0, r1
export ktj, ka, kb, kg, kh, ki, kj, kf, ks
export ktn, knk, kp
export xa, xt, xr, xg, xh, xi, xj, xf, xs, xn
export C_, S_, G_, H_, I_, J_, E_, F_, V_, K_Ptr
export KB, UU, KG, KH, KI, KJ, KE, KF, KC, KS, KP, KM, KD, KV, KU, KT
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
#      type bytes qtype     ctype  accessor
const KB = 1  # 1 boolean   char   kG
const UU = 2  # 16 guid     U      kU
const KG = 4  # 1 byte      char   kG
const KH = 5  # 2 short     short  kH
const KI = 6  # 4 int       int    kI
const KJ = 7  # 8 long      long   kJ
const KE = 8  # 4 real      float  kE
const KF = 9  # 8 float     double kF
const KC = 10 # 1 char      char   kC
const KS = 11 # * symbol    char*  kS

const KP = 12 # 8 timestamp long   kJ (nanoseconds from 2000.01.01)
const KM = 13 # 4 month     int    kI (months from 2000.01.01)
const KD = 14 # 4 date      int    kI (days from 2000.01.01)

const KN = 16 # 8 timespan  long   kJ (nanoseconds)
const KU = 17 # 4 minute    int    kI
const KV = 18 # 4 second    int    kI
const KT = 19 # 4 time      int    kI (millisecond)

C_ = Cchar
S_ = Cstring
G_ = Cuchar
H_ = Cshort
I_ = Cint
J_ = Clonglong
E_ = Cfloat
F_ = Cdouble
V_ = Void

immutable k0
    m::C_
    a::C_
    t::C_
    u::C_
    r::I_
end
K_Ptr = Ptr{k0}

# reference management
r0(x::K_Ptr) = ccall((@k_sym :r0), K_Ptr, (K_Ptr,), x)
r1(x::K_Ptr) = ccall((@k_sym :r1), K_Ptr, (K_Ptr,), x)

# head accessors
xa(x::K_Ptr) = unsafe_load(x).a
xt(x::K_Ptr) = unsafe_load(x).t
xr(x::K_Ptr) = unsafe_load(x).r

# scalar accessors
xg(x::K_Ptr) = unsafe_load(Ptr{G_}(x+8))
xh(x::K_Ptr) = unsafe_load(Ptr{H_}(x+8))
xi(x::K_Ptr) = unsafe_load(Ptr{I_}(x+8))
xj(x::K_Ptr) = unsafe_load(Ptr{J_}(x+8))
xe(x::K_Ptr) = unsafe_load(Ptr{E_}(x+8))
xf(x::K_Ptr) = unsafe_load(Ptr{F_}(x+8))
xs(x::K_Ptr) = unsafe_string(unsafe_load(Ptr{S_}(x+8)))

# vector accessors
xn(x::K_Ptr) = unsafe_load(Ptr{J_}(x+8))
xG(x::K_Ptr) = Ptr{G_}(x+16)
xH(x::K_Ptr) = Ptr{H_}(x+16)
xI(x::K_Ptr) = Ptr{I_}(x+16)
xJ(x::K_Ptr) = Ptr{J_}(x+16)
xE(x::K_Ptr) = Ptr{E_}(x+16)
xF(x::K_Ptr) = Ptr{F_}(x+16)


# scalar constructors
ktj(t::Integer, x::Integer) = ccall((@k_sym :ktj), K_Ptr, (I_, J_), t, x)
ka(x::I_) = ccall((@k_sym :ka), K_Ptr, (I_,), x)
kb(x::I_) = ccall((@k_sym :kb), K_Ptr, (I_,), x)
kg(x::I_) = ccall((@k_sym :kg), K_Ptr, (I_,), x)
kh(x::I_) = ccall((@k_sym :kh), K_Ptr, (I_,), x)
ki(x::I_) = ccall((@k_sym :ki), K_Ptr, (I_,), x)
kj(x::J_) = ccall((@k_sym :kj), K_Ptr, (J_,), x)
ke(x::F_) = ccall((@k_sym :ke), K_Ptr, (F_,), x)
kf(x::F_) = ccall((@k_sym :kf), K_Ptr, (F_,), x)
kc(x::I_) = ccall((@k_sym :kc), K_Ptr, (I_,), x)
ks(x::String) = ccall((@k_sym :ks), K_Ptr, (S_,), x)

# vector constructors
kp(x::String) = ccall((@k_sym :kp), K_Ptr, (S_,), x)
ktn(t::Integer, n::J_) = ccall((@k_sym :ktn), K_Ptr, (I_, J_), t, n)
knk(n) = begin @assert n == 0; ccall((@k_sym :ktn), K_Ptr, (I_,), 0) end
knk(n::I_, x::K_Ptr...) = ccall((@k_sym :ktn), K_Ptr, (I_, K_Ptr...), n, x...)

# communications
# extern I khpun(const S,I,const S,I),khpu(const S,I,const S),khp(const S,I),okx(K),
khpun(h::String, p::Integer, u::String, n::Integer) =
    ccall((@k_sym :khpu), I_, (S_, I_, S_, I_), h, p, u, n)
khpu(h::String, p::Integer, u::String) =
    ccall((@k_sym :khpu), I_, (S_, I_, S_), h, p, u)
khp(h::String, p::Integer) = ccall((@k_sym :khp), I_, (S_, I_), h, p)

kclose(h::Integer) = ccall((@k_sym :kclose), V_, (I_, ), h)

# K k(I,const S,...)
k_(h::Integer, m::String) =
    ccall((@k_sym :k), K_Ptr, (I_, S_, K_Ptr), h, m, K_Ptr(C_NULL))
k_(h::Integer, m::String, x::K_Ptr...) =
    ccall((@k_sym :k), K_Ptr, (I_, S_, K_Ptr...), h, m, x..., K_Ptr(C_NULL))
end # module k

using JuQ.k

#########################################################################
# Wrapper around q's C K type, with hooks to q reference
# counting and conversion routines to/from C and Julia types.
"""
    K(juliavar)
This converts a julia variable to a K object, which is a reference to a q object.
"""
type K
    x::K_Ptr # the actual K object
    function K(x::K_Ptr)
        px = new(x)
        finalizer(px, (x->r0(x.x)))
        return px
    end
end

type K_Vector{T} <: AbstractArray{T,1}
    o::K
    function (::Type{K_Vector{T}}){T}(o::K)
        t = xt(o.x)
        if(t != K_TYPE[T])
            throw(ArgumentError("type mismatch: t=$t, T=$T"))
        end
        return new{T}(o)
    end
end
K_Vector(o::K) = K_Vector{C_TYPE[xt(o.x)]}(o)
K_Vector{T}(a::Array{T,1}) = K_Vector(K(a))
Base.eltype{T}(v::K_Vector{T}) = T
Base.size{T}(v::K_Vector{T}) = (xn(v.o.x),)
Base.getindex{T}(v::K_Vector{T}, i::Integer) =
    unsafe_load(Ptr{T}(v.o.x + 16), i)

include("conversions.jl")

Base.eltype(x::K) = C_TYPE[abs(xt(x.x))]
Base.length(x::K) = 0<=xt(x.x)<98?xn(x.x):1
Base.size(x::K) = 0<=xt(x.x)<98?(xn(x.x),):()
Base.ndims(x::K) = UInt(0<=xt(x.x)<98)

# communications
hopen(h::String, p::Integer) = khp(h, p)
hclose = kclose

hget(h::Integer, m::String) = K(k_(h, m))
function hget(h::Integer, m::String, x...)
   x = map(K, x)
   r = k_(h, m, map(x->x.x, x)...)
   return K(r)
end
function hget(h::Tuple{String,Integer}, m)
   h = hopen(h...)
   r = hget(h, m)
   kclose(h)
   return r
end
function hget(h::Tuple{String,Integer}, m, x...)
   h = hopen(h...)
   r = hget(h, m, x...)
   kclose(h)
   return r
end
end # module
