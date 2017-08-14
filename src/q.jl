export @q_cmd
macro q_cmd(s) hget(0, s) end
function Base.show(io::IO, x::K)
    s = hget(0, "{` sv .Q.S[40 80;0;x]}", x)
    write(io, strip(String(s)))
end
