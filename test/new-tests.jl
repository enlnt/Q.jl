newref(x) = K_Ref(K_new(x))
@testset "K_new" begin
  @test (x = newref(1); (xt(x.x), xj(x.x)) == (-KJ, 1))
  @test (x = newref(Date(2000)); (xt(x.x), xj(x.x)) == (-KD, 0))
  @test (x = newref(DateTime(2000)); (xt(x.x), xj(x.x)) == (-KP, 0))
end
