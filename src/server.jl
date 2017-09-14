export @q_cmd
KDB_HANDLE[] = 0

function kerror()
    e = asarray(ee(K_(C_NULL)))
    unsafe_string(e[])
end
function apply(f, args...)
    x = K(args)
    r = dot_(kpointer(f), kpointer(x))
    if r == C_NULL
        throw(KdbException(kerror()))
    end
    K(r)
end

for T in (K_Lambda, K_Other, K_symbol)
    @eval (f::$T)() = f(nothing)
    @eval (f::$T)(args...) = apply(f, args...)
end

const q_parse = K(k(0, "parse"))
const q_eval = K(k(0, "eval"))

macro q_cmd(s) q_parse(s) end
Base.run(x::K_List, args...) = (r = q_eval(x); length(args) == 0 ? r : r(args...))

# function Base.show(io::IO, x::Union{K_Other,K_Lambda})
#     s = k(0, "{` sv .Q.S[40 80;0;x]}", K_new(x))
#     try
#         write(io, strip(transcode(String, kG(s))))
#     finally
#         r0(s)
#     end
#     nothing
# end
