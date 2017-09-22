# Convert Julia expressions to K parse trees
const OPCODE1 = Dict(
    :+     => 1,
    :-     => 2,
    :flip  => 1,
    :neg   => 2,
    :first => 3,        # *:
    :reciprocal =>  4,  # %:
    :where      =>  5,  # &:
    :reverse    =>  6,  # |:
    :null       =>  7,  # ^:
    :group      =>  8,  # =:
    :hopen      =>  9,  # <:
    :hclose     => 10,  # >:
    :string     => 11,  # $:
    #              12   #:,:
    :count      => 13,  # #:
    :floor      => 14,  # _:
    :not        => 15,  # ~:
    :key        => 16,  # !:
    :distinct   => 17,  # ?:
    :type_      => 18,  # @:
    :value      => 19,  # .:
    :read0      => 20,  # 0::
    :read1      => 21,  # 1::
    #              22   # 2::
    :avg        => 23,
    :last       => 24,
    :sum        => 25,
    :prd        => 26,
    :min        => 27,
    :max        => 28,
    :exit       => 29,
    :getenv     => 30,
    :abs        => 31,
    :sqrt       => 32,
    :log        => 33,
    :exp        => 34,
    :sin        => 35,
    :asin       => 36,
    :cos        => 37,
    :acos       => 38,
    :tan        => 39,
    :atan       => 40,
    :enlist     => 41,
    :var        => 42,
    :dev        => 43,
)
const OPCODE2 = Dict(
    :+ => 1,
    :- => 2,
    :* => 3,
    :/ => 4,
    :& => 5,
    :| => 6,
    :^ => 7,  # should this be 32 (xexp)?
    :(==) => 8,
    :< => 9,
    :> => 10,
    :$ => 11,
)

# q)asc string (key .q)where{$[100=type x;1=count(value x)1;0b]}each get .q
const FUNC1 = Set([
    :asc,
    :avgs,
    :cols,
    :desc,
    :fkeys,
    :gtime,
    :iasc,
    :idesc,
    :keys,
    :lower,
    :ltrim,
    :med,
    :meta,
    :next,
    :parse,
    :rand,
    :rank,
    :rtrim,
    :sdev,
    :show,
    :signum,
    :svar,
    :tables,
    :til,
    :trim,
    :ungroup,
    :upper,
    :view,
    :views,
])

# q)asc string (key .q)where {$[100=type x;2=count(value x)1;0b]}each get .q
const FUNC2 = Set([
    :asof,
    :cross,
    :cut,
    :each,
    :ema,
    :except,
    :fby,
    :ij,
    :ijf,
    :inter,
    :lj,
    :ljf,
    :mavg,
    :mcount,
    :mdev,
    :mmax,
    :mmin,
    :mod,
    :msum,
    :over,
    :peach,
    :pj,
    :prior,
    :rotate,
    :scan,
    :scov,
    :set,
    :sublist,
    :sv,
    :uj,
    :ujf,
    :vs,
    :xasc,
    :xbar,
    :xcol,
    :xcols,
    :xdesc,
    :xgroup,
    :xkey,
    :xlog,
    :xprev,
    :xrank,
])

# q)asc string (key .q)where {$[100=type x;3=count(value x)1;0b]}each get .q
const FUNC3 = Set([
    :aj,
    :aj0,
    :ej,
    :ssr,
])

func(::Type{Val{false}}, x::Symbol) = ks(string(".q.", x))
func(::Type{Val{true}}, x::Symbol) = k(0, string(".q.", x))

function op1(x::Symbol)
    x in FUNC1 && return func(Val{GOT_Q}, x)
    opcode = get(OPCODE1, x, -1)
    opcode == -1 ? ks(x) : ktj(101, opcode)
end

function op2(x::Symbol)
    x in FUNC2 && return func(Val{GOT_Q}, x)
    opcode = get(OPCODE2, x, -1)
    opcode == -1 ? ks(x) : ktj(102, opcode)
end

call(f) = knk(2, op(f, 1), ktj(101, 0))

function call(f, a)
    g = K_Ref(op1(f))  # guarded reference
    knk(2, r1(g.x), K_new(a))
end

function call(f, a, b)
    g = K_Ref(op2(f))
    x = K_Ref(K_new(a))
    y = K_Ref(K_new(b))
    knk(3, r1(g.x), r1(x.x), r1(y.x))
end

function call(f, a, b, c)
    g = K_Ref(op2(f))
    x = K_Ref(K_new(a))
    y = K_Ref(K_new(b))
    z = K_Ref(K_new(c))
    f in (:+, :*) ?
        knk(3, r1(g.x), r1(x.x), knk(3, r1(g.x), r1(y.x), r1(z.x))) :
        knk(4, r1(g.x), r1(x.x), r1(y.x), r1(z.x))
end

function call(f, args...)  # 4 or more args
    n = length(args)
    g = K_Ref(ks(f))
    if xt(g.x) == -KS
        args = map(a->K_Ref(K_new(a)), args)
        return knk(n+1, r1(g.x), map(a->r1(a.x), args)...)
    else
        error("nyi")
    end
end

function tree(ex::Expr)
    if ex.head === :call
        return call(ex.args[1], ex.args[2:end]...)
    end
    error("expression is too complex")
end

K_new(ex::Expr) = tree(ex)
