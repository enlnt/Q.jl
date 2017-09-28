# This should be run from q as
# J)include("test/sd-tests.jl")
# J)@test x > 0
using Base.Test
using Q._k

fds = Cint[0, 0]
@test ccall(:pipe, Cint, (Ptr{Cint},), fds) == 0
x = 0
function f(d::I_)
    global x = d
    k(0, "x:$d")
    buf = Cchar[0]
    ccall(:read, Cint, (Cint, Ptr{Void}, Csize_t),
          d, pointer(buf), 1) 
    0  # K_(C_NULL)
end
const f_c = cfunction(f, Int, (I_, ))
v = sd1(fds[1], f_c)
@test xi(v) == fds[1]
r0(v)
@test ccall(:write, Cint, (Cint, Ptr{Void}, Csize_t),
            fds[2], pointer("x"), 1) == 1
# sd0(fds[1])

