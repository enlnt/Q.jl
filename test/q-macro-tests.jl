@testset "@q macro" begin
    @test 4 == @q 2 + 2
    @test [0, 1] == @q til(2)
    @test begin
        @q begin
          a = 2
          b = 42
        end
        @q(a) == 2 && @q(b) == 42
    end
    @test begin
        f = Dict(:x=>42)
        e = K(:(x+y))
        Q.resolve!(e, f)
        e == K(:(42+y))
    end
    @test (x = 42; 43 == @q let x;x+1 end)
    @test q(".z.K") == @q _z.K
end
