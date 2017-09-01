export @q_cmd
# TODO: Use dot_ here.
_apply(f, args...) = K(k(0, ".", K_new(f), K_new(args)))
(f::K_Lambda)() = f(nothing)
(f::K_Other)() = f(nothing)
(f::K_Lambda)(args...) = _apply(f, args...)
(f::K_Other)(args...) = _apply(f, args...)

const Q_PARSE = "{\$[0=t:type e:parse x;{y;eval x}e;t=-11;eval e;e]}"
macro q_cmd(s) _E(k(0, Q_PARSE, kp(s))) end
function Base.show(io::IO, x::K)
    s = k(0, "{` sv .Q.S[40 80;0;x]}", K_new(x))
    try
        write(io, strip(unsafe_string(pointer(s), xn(s))))
    finally
        r0(s)
    end
    nothing
end
