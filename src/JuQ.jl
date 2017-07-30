module JuQ
module k
export r0, r1
export kg, kh, ki, kj, kf, ks
export xa, xt, xr, xg, xh, xi, xj, xf, xs
export C_, S_, G_, H_, I_, J_, E_, F_, V_, K_Ptr
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
    d::J_
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

# scalar constructors
ktj(t::I_, x::J_) = ccall((@k_sym :ktj), K_Ptr, (I_, J_), t, x)
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
        finalizer(px, r0)
        return px
    end
end

include("conversions.jl")

end # module
