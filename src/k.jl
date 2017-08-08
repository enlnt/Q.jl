module k  # k.h wrappers
export k_, khpun, khpu, khp, okx, kclose
export ymd, dj
export r0, r1
export ktj, ka, kb, kg, kh, ki, kj, ke, kf, sn, ss, ks, kc
export ktn, knk, kp, xT, xD
export xa, xt, xr, xg, xh, xi, xj, xf, xs, xn
export C_, S_, G_, H_, I_, J_, E_, F_, V_, U_, K_Ptr
export KB, UU, KG, KH, KI, KJ, KE, KF, KC, KS, KP, KM, KD, KN, KU, KV, KT,
       XT, XD
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

# table,dict
const XT = 98 #   x->k is XD
const XD = 99 #   kK(x)[0] is keys. kK(x)[1] is values.

C_ = Cchar
S_ = Cstring
G_ = Cuchar
H_ = Cshort
I_ = Cint
J_ = Clonglong
E_ = Cfloat
F_ = Cdouble
V_ = Void
U_ = UInt128

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
kb(x::Integer) = ccall((@k_sym :kb), K_Ptr, (I_,), x)
kg(x::Integer) = ccall((@k_sym :kg), K_Ptr, (I_,), x)
ka(x::Integer) = ccall((@k_sym :ka), K_Ptr, (I_,), x)
kh(x::Integer) = ccall((@k_sym :kh), K_Ptr, (I_,), x)
ki(x::Integer) = ccall((@k_sym :ki), K_Ptr, (I_,), x)
kj(x::Integer) = ccall((@k_sym :kj), K_Ptr, (J_,), x)
ke(x::Real) = ccall((@k_sym :ke), K_Ptr, (F_,), x)
kf(x::Real) = ccall((@k_sym :kf), K_Ptr, (F_,), x)
kc(x::Integer) = ccall((@k_sym :kc), K_Ptr, (I_,), x)
sn(x::String, n::Integer) = ccall((@k_sym :sn), S_, (S_,I_), x, n)
ss(x::String) = ccall((@k_sym :ss), S_, (S_,), x)
ss(x::Symbol) = ccall((@k_sym :ss), S_, (S_,), x)
ks(x::String) = ccall((@k_sym :ks), K_Ptr, (S_,), x)

# vector constructors
kp(x::String) = ccall((@k_sym :kp), K_Ptr, (S_,), x)
ktn(t::Integer, n::J_) = ccall((@k_sym :ktn), K_Ptr, (I_, J_), t, n)
knk(n) = begin @assert n == 0; ccall((@k_sym :ktn), K_Ptr, (I_,), 0) end
knk(n::I_, x::K_Ptr...) = ccall((@k_sym :ktn), K_Ptr, (I_, K_Ptr...), n, x...)

# table, dictionary
xT(x::K_Ptr) = ccall((@k_sym :xT), K_Ptr, (K_Ptr, ), x)
xD(x::K_Ptr, y::K_Ptr) = ccall((@k_sym :xD), K_Ptr, (K_Ptr, K_Ptr), x, y)

# communications
# extern I khpun(const S,I,const S,I),khpu(const S,I,const S),khp(const S,I),okx(K),
khpun(h::String, p::Integer, u::String, n::Integer) =
    ccall((@k_sym :khpu), I_, (S_, I_, S_, I_), h, p, u, n)
khpu(h::String, p::Integer, u::String) =
    ccall((@k_sym :khpu), I_, (S_, I_, S_), h, p, u)
khp(h::String, p::Integer) = ccall((@k_sym :khp), I_, (S_, I_), h, p)
okx(x::K_Ptr) = ccall((@k_sym :okx), I_, (K_Ptr, ), x)
kclose(h::Integer) = ccall((@k_sym :kclose), V_, (I_, ), h)

# Dates
ymd(y::Integer, m::Integer, d::Integer) =
    ccall((@k_sym :ymd), I_, (I_, I_, I_), y, m, d)
dj(j::Integer) = ccall((@k_sym :dj), I_, (I_, ), j)

# K k(I,const S,...)
k_(h::Integer, m::String) =
    ccall((@k_sym :k), K_Ptr, (I_, S_, K_Ptr), h, m, K_Ptr(C_NULL))
k_(h::Integer, m::String, x::K_Ptr...) =
    ccall((@k_sym :k), K_Ptr, (I_, S_, K_Ptr...), h, m, x..., K_Ptr(C_NULL))
end # module k
