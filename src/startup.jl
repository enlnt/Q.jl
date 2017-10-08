export GOT_Q, @k_sym, C_SO
#C_SO = C_NULL
const SYS_CHAR = Dict(
    :Linux => 'l',
    :Darwin => 'm',
)
const SYS_ARCH = @sprintf("%c%d", SYS_CHAR[Sys.KERNEL], Sys.WORD_SIZE)

impl_dot(x, y) = (error("not implemented"); x)
impl_ee(x) = (error("not implemented"); x)
impl_dl(f, n) = (error("not implemented"); K_NULL)
function impl_khp(h::Cstring, p::Cint)
    x = k(0, "hopen", ks(string(":", unsafe_string(h), ":", p)))
    x == K_NULL ? Cint(-1) : xi(x)
end
function __init__()
    h = unsafe_load(cglobal(:jl_exe_handle, Ptr{Void}))
    # Is Julia running embedded in q?
    global GOT_Q = Libdl.dlsym_e(h, :b9) != C_NULL
    global __dot, __ee, __dl, __khp
    if GOT_Q  # Get q C API from the current process
        global const C_SO = h
        __khp[] = cfunction(impl_khp, I_, (Cstring, Cint))
    else
        path = joinpath(dirname(@__FILE__), SYS_ARCH, "c")
        global const C_SO = Libdl.dlopen(path,
                Libdl.RTLD_LAZY|Libdl.RTLD_DEEPBIND|Libdl.RTLD_GLOBAL)
        __dot[] = cfunction(impl_dot, K_, (K_, K_))
        __ee[] = cfunction(impl_ee, K_, (K_, ))
        __dl[] = cfunction(impl_dl, K_, (Ptr{V_}, I_))
    end
end  # __init__

macro k_sym(func)
    z = Symbol("__", func.args[1])
    isdefined(z) || @eval global const $z = Ref{Ptr{Void}}(C_NULL)
    quote begin
        if $z[] == C_NULL
            $z[] = Libdl.dlsym(C_SO::Ptr{Void}, $(esc(func)))
        end
        $z[]
    end end
end
