using Q.K_KeyTable
@testset "table tests" begin
  @test_throws ArgumentError K_KeyTable(kj(0))
  @test_throws ArgumentError K_KeyTable(xD(ktn(0,0),ktn(0,0)))
  let x = K_Table(a=Int[]), p = kpointer(x)
    @test_throws ArgumentError K_KeyTable(xD(r1(p),ktn(0,0)))
    @test (kt = K_KeyTable(xD(r1(p), r1(p))); xt(kpointer(kt)) == XD)
  end
  @test (x = K_KeyTable(1; a=Int[], b=Int[]); size(x) == (0, 2))
  @test begin
    t = K_KeyTable(1; a=[0, 1, 2], b=[0., 10., 20.])
    show_to_string(t) == """
    3×2 Q.K_KeyTable
    │ Row │ a │ b    │
    ├─────┼───┼──────┤
    │ 1   │ 0 │ 0.0  │
    │ 2   │ 1 │ 10.0 │
    │ 3   │ 2 │ 20.0 │"""
  end
  @test (x = K_KeyTable(1;a=Int[],b=Int[]); x[:a] == x[:b] == Int[])
end
