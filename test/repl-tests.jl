using Base.Test
import Base: REPL, LineEdit
import Q.KdbMode: install_kdb_mode

mutable struct FakeTerminal <: Base.Terminals.UnixTerminal
    in_stream::Base.IO
    out_stream::Base.IO
    err_stream::Base.IO
    hascolor::Bool
    raw::Bool
    size::Tuple{Int,Int}
    FakeTerminal(stdin, stdout, stderr, hascolor=false) =
        new(stdin, stdout, stderr, hascolor, false, (24, 80))
end

Base.Terminals.hascolor(t::FakeTerminal) = t.hascolor
Base.Terminals.raw!(t::FakeTerminal, raw::Bool) = t.raw = raw
Base.Terminals.size(t::FakeTerminal) = t.size

function fake_repl()
    p = [Pipe() for _ in 1:3]
    map(Base.link_pipe, p)
    term = FakeTerminal(p[1].out, p[2].in, p[3].in)
    repl = Base.REPL.LineEditREPL(term)
    repl.history_file = false
    p[1].in, p[2].out, p[3].out, repl
end

stdin, stdout, stderr, repl = fake_repl()


repltask = @async begin
    Base.REPL.run_repl(repl)
end
@testset "REPL" begin
    write(stdin, "42\r")
    @test (out = readuntil(stdout, "\n\n"); contains(out, "42\n"))
    @test install_kdb_mode(repl) &&
        (contains(readline(stderr), "q)") ||
         contains(readline(stderr), "q)"))
    write(stdin, "\\")
    readuntil(stdout, "q)")
    write(stdin, "til 10\r")
    @test (out = readline(stdout); contains(out, "til 10"))
    @test (out = readline(stdout); contains(out, "0 1 2 3"))
end

# Close REPL ^D
write(stdin, '\x04')
wait(repltask)
