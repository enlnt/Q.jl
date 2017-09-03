@testset "list tests" begin
  @testset "list from low level" begin
    @test (x = K(ktn(0, 0)); eltype(x) == K)
  end
  @testset "list constructors" begin
    @test (x = K[]; eltype(x) == K)
    @test (x = K[1, ""]; eltype(x) == K && x[1] == 1)
    @test (x = K((1, [2, 3])); x[1] == 1 && x[2] == [2, 3])
    @test (x = K((1, 2.)); x[1] == 1 && x[2] == 2.)
  end
end
