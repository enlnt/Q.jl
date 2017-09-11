module Kdb
import Q._k: k, khp
const OS = Dict(:Darwin => 'm', :Linux => 'l', :Windows => 'w')
const QHOME = get(Dict(ENV), "QHOME") do
    joinpath(homedir(), "q")
end
const STARTUP_CODE = """
p:1024
while[0~@[system;"p ",string p;0];p+:1]
-1 string p
\\1 /dev/null
"""

"""
Returns the path to the kdb+ binary.
"""
function kdb_binary()
    os = OS[Sys.KERNEL]
    binary = joinpath(QHOME, "$(os)64", "q")
    if isfile(binary)
        return binary
    end
    joinpath(QHOME, "$(os)32", "q")
end

q_command() = `$(kdb_binary())`

"""
Start a slave kdb+ process and return a comm handle.
"""
function start()
    p = spawn(q_command(), (Pipe(), Pipe(), STDERR))
    write(p.in, STARTUP_CODE)
    port = readline(p.out)
    close(p.out)
    parse(Int, port), p
end

function stop(handle, process)
    k(handle, "exit 0")
    wait(process)
    process.exitcode
end

function __init__()
    global QBIN
    QBIN = kdb_binary()
end
end  # module Kdb
