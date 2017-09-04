using Base.Filesystem
const OS = Dict(:Darwin => 'm', :Linux => 'l', :Windows => 'w')
const QHOME = get(Dict(ENV), "QHOME") do
    joinpath(homedir(), "q")
end
const STARTUP_CODE = """
p:1024;while[0~@[system;"p ",string p;0];p+:1];-1 string p;
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

"""
Temporarily changes the current working directory to a tempdir()
and applies function f before returning.

"""
function cdtemp(f::Function)
    mktempdir() do dir
        cd(f, dir)
    end
end

"""
Starts a server and applies function f to port before
shutting it down.
"""
function server(f::Function; user="")
    kdb = kdb_binary()
    if !isfile(kdb)
        println("kdb+ is not installed")
        return true
    end
    cdtemp() do
        open(joinpath(pwd(), "q.q"), "w") do file
            write(file, STARTUP_CODE)
        end
        if user != ""
            open(joinpath(pwd(), "login"), "w") do file
                write(file, user)
            end
            cmd = `$kdb -U login`
        else
            cmd = `$kdb`
        end
        stream, process = open(cmd)
        port = parse(Int32, readline(stream))
        try
            return f(port)
        finally
            close(stream)
            kill(process)
        end
    end
end
function show_to_string(args...)
  buffer = IOBuffer()
  show(buffer, args...)
  String(take!(buffer))
end
