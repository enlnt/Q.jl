@testset "reference counting tests" begin
  let x = K(1)
    @test auto_r0(K_new, x) do p; xr(p) == 1 end
    @test xr(kpointer(x)) == 0
  end
end
