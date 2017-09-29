function process_julia_events(d::I_)
    # NB: process_events(false) calls jl_process_events(loop)
    # which in turn calls uv_run(loop, UV_RUN_NOWAIT).
    k(0, "1 enlist\".\"")
    try
        Base.process_events(false)
    catch err
        println(err)
    end
    0
end
const process_julia_events_c = cfunction(process_julia_events, Int, (I_, ))
function start_julia()
    loop = Base.eventloop()
    d = ccall(:uv_backend_fd, Cint, (Ptr{Void}, ), loop)
    r0(sd1(d, process_julia_events_c))
end
