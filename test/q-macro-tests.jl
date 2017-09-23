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
end
