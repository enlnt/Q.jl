@testset "table tests" begin
  let x = K_Table(a=[1, 2])
    @test x == K_Table(Any[[1,2]], [:a])
    @test xt(kpointer(x)) == XT
    @test ncol(x) == 1
    @test nrow(x) == 2
    @test DataFrames.columns(x) == [:a]
    @test DataFrames.index(x) == DataFrames.Index(Dict(:a=>1), Symbol[:a])
    @test x[1] == [1, 2]
    @test x[2,1] == 2
    @test (x′ = K(r1(kpointer(x))); x == x′)
  end
end
