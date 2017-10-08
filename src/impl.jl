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
function impl_khp(h::Cstring, p::Cint)
    x = k(0, "hopen", ks(string(":", unsafe_string(h), ":", p)))
    x == K_NULL ? Cint(-1) : xi(x)
end
