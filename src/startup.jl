export GOT_Q, @k_sym
let h = unsafe_load(cglobal(:jl_exe_handle, Ptr{Void}))
    # Is Julia running embedded in q?
    global const GOT_Q = Libdl.dlsym_e(h, :b9) != C_NULL
end

if GOT_Q  # Get q C API from the current process
    macro k_sym(func)
        esc(func)
    end
else      # Load "c" DLL
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
end
