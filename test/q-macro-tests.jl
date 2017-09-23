@testset "@q macro" begin
    @test 4 == @q 2 + 2
    @test [0, 1] == @q til(2)
end
