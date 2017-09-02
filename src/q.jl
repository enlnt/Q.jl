export @q_cmd

(f::JuQ.K_Other)() = f(nothing)
function (f::JuQ.K_Other)(args...)
   p = k(0, ".", K_new(f), K_new(args))
   K(p)
end

const Q_PARSE = "{\$[0=t:type e:parse x;{y;eval x}e;t=-11;eval e;e]}"
macro q_cmd(s) _E(k(0, Q_PARSE, kp(s))) end
function Base.show(io::IO, x::K)
    s = k(0, "{` sv .Q.S[40 80;0;x]}", r1(x.o.x))
    try
        write(io, strip(unsafe_string(pointer(s), xn(s))))
    finally
        r0(s)
    end
    nothing
end
