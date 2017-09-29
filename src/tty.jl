import Base.Filesystem
const O_RDONLY = Filesystem.JL_O_RDONLY
const O_RDWR = Filesystem.JL_O_RDWR

function reopen_tty()
    fd1 = ccall(:open, Cint, (Cstring, Cint), "/dev/tty", O_RDWR)
    if fd1 == -1
        error(Libc.strerror())
    end
    try
        fd2 = ccall(:dup2, Cint, (Cint, Cint), fd1, 0)
        if fd2 == -1
            error(Libc.strerror())
        end
        Base.reinit_stdio()
    finally
        if ccall(:close, Cint, (Cint, ), fd1) == -1
            error(Libc.strerror())
        end
    end
end
