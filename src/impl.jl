# Implementation of Kx API functions that are missing either in q or c.o.
impl_dot(x, y) = (error("not implemented"); x)
impl_ee(x) = (error("not implemented"); x)
function impl_dl(f::Ptr{V_}, n::Integer)
    x = ka(112)
    # m, a t, u = (1, -128, 112, n)
    matu = C_[1, -128, 112, n]
    unsafe_copy!(Ptr{C_}(x), pointer(matu), 4)
    unsafe_store!(Ptr{J_}(x+8), 1)
    unsafe_store!(Ptr{Ptr{V_}}(x+16), f)
    x
end
_dot(f::Ptr{V_}, x1) = ccall(f, K_, (K_, ), x1)
_dot(f::Ptr{V_}, x1, x2) = ccall(f, K_, (K_, K_), x1, x2)
_dot(f::Ptr{V_}, x1, x2, x3) = ccall(f, K_, (K_, K_, K_), x1, x2, x3)
_dot(f::Ptr{V_}, x1, x2, x3, x4) = ccall(f, K_,
    (K_, K_, K_, K_), x1, x2, x3, x4)
function impl_dot(f::K_, x::K_)
    p = unsafe_load(Ptr{Ptr{V_}}(f+16))
    n = unsafe_load(f).u
    @assert xn(x) == n  # XXX: Projections are nyi.
    _dot(p, kK(x)...)
end
function impl_khp(h::Cstring, p::Cint)
    x = k(0, "hopen", ks(string(":", unsafe_string(h), ":", p)))
    x == K_NULL ? Cint(-1) : xi(x)
end
