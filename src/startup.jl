export @k_sym

const SYS_CHAR = Dict(
    :Linux => 'l',
    :Darwin => 'm',
)
const SYS_ARCH = @sprintf("%c%d", SYS_CHAR[Sys.KERNEL], Sys.WORD_SIZE)
const C_SO_PATH = joinpath(dirname(@__FILE__), SYS_ARCH, "c")
const C_SO = Libdl.dlopen(C_SO_PATH,
            Libdl.RTLD_LAZY|Libdl.RTLD_DEEPBIND|Libdl.RTLD_GLOBAL)

macro k_sym(func)
    :(($(esc(func)), C_SO_PATH))
end
