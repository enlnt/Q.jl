function process_julia_events(d::I_)
    # NB: process_events(false) calls jl_process_events(loop)
    # which in turn calls uv_run(loop, UV_RUN_NOWAIT).
    #k(0, "1 enlist\".\"")
    n = -1
    try
        n = Base.process_events(false)
    catch err
        println(err)
    end
    #k(0, "1 string $n")
    write(notification_pipe.in, 'e')
    ccall(:jl_breakpoint, Void, (Any,), d)
    0
end
const process_julia_events_c = cfunction(process_julia_events, Int, (I_, ))

function process_julia_notification(d::I_)
    c = read(notification_pipe.out, 1)
    #k(0, "1 enlist\"$c\"")
    process_julia_events(d)
end
const process_julia_notification_c = cfunction(process_julia_notification,
    Int, (I_, ))

const notification_pipe = Pipe()
function start_julia()
    loop = Base.eventloop()
    d = ccall(:uv_backend_fd, Cint, (Ptr{Void}, ), loop)
    r0(sd1(d, process_julia_events_c))
    Base.link_pipe(notification_pipe)
    write(notification_pipe.in, 's')
    d = Base._fd(Q.notification_pipe.out).fd
    r0(sd1(d, process_julia_notification_c))
    ccall(:jl_breakpoint, Void, (Any,), notification_pipe)
end
