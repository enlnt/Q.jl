export @q_cmd
macro q_cmd(s) _E(k(0, s)) end
function Base.show(io::IO, x::K)
    s = k(0, "{` sv .Q.S[40 80;0;x]}", r1(x.o.x))
    write(io, strip(unsafe_string(pointer(s))))
    r0(s)
    nothing
end
