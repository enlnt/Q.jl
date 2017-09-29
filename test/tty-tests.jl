# julia -e 'include("test/tty-tests.jl")' < /dev/null
include("src/tty.jl")
println(string(STDIN))
reopen_tty()
println(string(STDIN))
Base._start()
