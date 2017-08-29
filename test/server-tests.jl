@testset "q commands" begin
  @test q`til 3` == [0, 1, 2]
end 