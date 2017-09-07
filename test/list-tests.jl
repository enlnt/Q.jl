@testset "list tests" begin
  @testset "list from low level" begin
    @test (x = K(ktn(0, 0)); eltype(x) == K)
  end
  @testset "list constructors" begin
    @test (x = K[]; eltype(x) == K)
    @test (x = K[1, ""]; eltype(x) == K && x[1] == 1)
    @test (x = K((1, [2, 3])); x[1] == 1 && x[2] == [2, 3])
    @test (x = K((1, 2.)); x[1] == 1 && x[2] == 2.)
    @test (x = K([1 2]); x[2][1] == 2)
  end
  @testset "list setters" begin
    let x = K["", 1, 2, 3], a = K(0)
      @test (x[2:end] = a; xr(x.a[2]) == 3)
      @test (x[2:end] = 1; xr(kpointer(a)) == 0)
    end
  end
  @testset "list push/append" begin
    @test (x = K[]; push!(x, ""); push!(x, 1); x[2][] == 1)
    @test (x = K[]; append!(x, K["",1]); x[2][] == 1)
  end
end
