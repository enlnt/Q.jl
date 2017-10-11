using TableTraits
using NamedTuples
import IterableTables

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
  @test (x = K_Table(@NT(a::Int, b::Float64), 3); size(x) == (3, 2))
  @test begin
    t = K_Table(a=[1])
    Q.coldata(t)[1] = push!(t[1], 2)
    Q.coldata(t)[1] = push!(t[1], 3)
    t[1] == [1, 2, 3]
  end
end

@testset "table iterator tests" begin
  let t = K_Table(a=[0, 1, 2], b=[0., 10., 20.]), ti = getiterator(t)
    @test isiterable(t)
    @test isiterabletable(t)
    @test length(ti) == 3
    @test eltype(ti) == typeof(@NT(a=0, b=0.))
    @test start(ti) == 1
    @test collect(ti) == [
      @NT(a=0, b=0.),
      @NT(a=1, b=10.),
      @NT(a=2, b=20.),
    ]
  end
  @test K_Table([@NT(a=1), @NT(a=2)]) == DataFrame(a=[1,2])
  @test K_Table(@NT(a=i) for i in 1:3 if i != 2) == DataFrame(a=[1,3])
end
