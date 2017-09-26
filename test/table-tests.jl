@testset "table tests" begin
  let x = K_Table(a=[1, 2])
    @test x == K_Table(Any[[1,2]], [:a])
    @test xt(kpointer(x)) == XT
    @test ncol(x) == 1
    @test nrow(x) == 2
    @test Q.colnames(x) == [:a]
    @test DataFrames.index(x) == DataFrames.Index(Dict(:a=>1), Symbol[:a])
    @test x[1] == [1, 2]
    @test x[2,1] == 2
    @test (x′ = K(r1(kpointer(x))); x == x′)
    @test begin
      t = K_Table(a=[0, 1, 2], b=[0., 10., 20.])
      show_to_string(t) == """
      3×2 Q.K_Table
      │ Row │ a │ b    │
      ├─────┼───┼──────┤
      │ 1   │ 0 │ 0.0  │
      │ 2   │ 1 │ 10.0 │
      │ 3   │ 2 │ 20.0 │"""
    end
    @test (x = DataFrame(a=1:3, b=[10., 20, 30]); x == K(x));
    @test (x = K_Table(a=Int[]); names(names!(x, [:b])) == [:b])
    @test (x = K_Table(a=Int[]); x[:a] == Int[])
  end
end

using TableTraits
using NamedTuples
@testset "table iterator tests" begin
  let t = K_Table(a=[0, 1, 2], b=[0., 10., 20.]), ti = getiterator(t)
    @test length(ti) == 3
    @test eltype(ti) == typeof(@NT(a=0, b=0.))
    @test start(ti) == 1
    @test collect(ti) == [
      @NT(a=0, b=0.),
      @NT(a=1, b=10.),
      @NT(a=2, b=20.),
    ]
  end
end
