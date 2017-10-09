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

const b100 = [  # in alphabetical order
    "aj",
    "aj0",
    "asc",
    "asof",
    "avgs",
    "cols",
    "cross",
    "cut",
    "desc",
    "each",
    "ej",
    "ema",
    "except",
    "fby",
    "fkeys",
    "gtime",
    "iasc",
    "idesc",
    "ij",
    "ijf",
    "inter",
    "keys",
    "lj",
    "ljf",
    "lower",
    "ltrim",
    "mavg",
    "mcount",
    "mdev",
    "med",
    "meta",
    "mmax",
    "mmin",
    "mod",
    "msum",
    "next",
    "over",
    "parse",
    "peach",
    "pj",
    "prior",
    "rand",
    "rank",
    "rotate",
    "rtrim",
    "scan",
    "scov",
    "sdev",
    "set",
    "show",
    "signum",
    "ssr",
    "sublist",
    "sv",
    "svar",
    "tables",
    "til",
    "trim",
    "uj",
    "ujf",
    "ungroup",
    "upper",
    "view",
    "views",
    "vs",
    "wj",
    "wj1",
    "ww",
    "xasc",
    "xbar",
    "xcol",
    "xcols",
    "xdesc",
    "xgroup",
    "xkey",
    "xlog",
    "xprev",
    "xrank",
]

const b101 = [
    # "::",       #  0
    "flip",       #  1 +:
    "neg",        #  2 -:
    "first",      #  3 *:
    "reciprocal", #  4 %:
    "where",      #  5 &:
    "reverse",    #  6 |:
    "null",       #  7 ^:
    "group",      #  8 =:
    "hopen",      #  9 <:
    "hclose",     # 10 >:
    "string",     # 11 $:
    #             # 12 ,:
    "count",      # 13 #:
    "floor",      # 14 _:
    "not",        # 15 ~:
    "key",        # 16 !:
    "distinct",   # 17 ?:
    "type_",      # 18 @:
    "value",      # 19 .:
    "read0",      # 20 0::
    "read1",      # 21 1::
    #             # 22 2::
    "avg",        # 23
    "last",       # 24
    "sum",        # 25
    "prd",        # 26
    "min",        # 27
    "max",        # 28
    "exit",       # 29
    "getenv",     # 30
    "abs",        # 31
    "sqrt",       # 32
    "log",        # 33
    "exp",        # 34
    "sin",        # 35
    "asin",       # 36
    "cos",        # 37
    "acos",       # 38
    "tan",        # 39
    "atan",       # 40
    "enlist",     # 41
    "var",        # 42
    "dev",        # 43
]

const b102 = [
    "and",        #  5 &
    "or",         #  6 |
    # ...
    "mmu",        # 11 $
    # ...
    "lsq",        # 16 !
    "in",         # 23
    "within",     # 24
    "like",       # 25
    "bin",        # 26
    "ss",         # 27
    "insert",     # 28
    "wsum",       # 29
    "wavg",       # 30
    "div",        # 31
    "xexp",       # 32
    "setenv",     # 33
    "binr",       # 34
    "cov",        # 35
    "cor",        # 36
]

const b104 = [
    "md5",
    "attr",
    "upsert",
    "hcount",
    "eval",
    "reval",
]

const res = [b100; b101; b102; b104]

@eval struct _Q
    $([Symbol(x) for x in res]...)
    _Q() = new($([K(k(0, rstrip(x, ['_']))) for x in res]...))
end


# function Base.show(io::IO, x::Union{K_Other,K_Lambda})
#     s = k(0, "{` sv .Q.S[40 80;0;x]}", K_new(x))
#     try
#         write(io, strip(transcode(String, kG(s))))
#     finally
#         r0(s)
#     end
#     nothing
# end
function __init__()
    f = dl(_eval_string_c, 1)
    r0(k(0, "{.J.e::x}", f))
end
