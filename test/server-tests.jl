qa(cmd) = asarray(k(0, cmd))
qa(cmd, x...) = asarray(k(0, cmd, map(K_new, x)...))
@testset "server-side low level" begin
  @test begin  # dot_
    f = k(0, "til")
    af = asarray(f)  # ensure r0
    x = knk(1, kj(3))
    ax = asarray(x)  # ensure r0
    asarray(dot_(f, x)) == [0, 1, 2]
  end
  @test begin  # ee
    f = k(0, "til")
    af = asarray(f)    # ensure r0
    x = knk(1, kc(99)) # ,"c"
    ax = asarray(x)    # ensure r0
    unsafe_string(asarray(ee(dot_(f, x)))[]) == "type"
  end
  @testset "msg to handle 0" begin
    # using k(0, ..)
    @test qa("{x}", 1)[] == 1
    @test qa("{y}", 1, 2)[] == 2
    @test qa("{z}", 1, 2, 3)[] == 3
    @test qa("{[a;b;c;d]d}", 1, 2, 3, 4)[] == 4
    @test qa("{[a;b;c;d;e]e}", 1, 2, 3, 4, 5)[] == 5
    @test qa("{[a;b;c;d;e;f]f}", 1, 2, 3, 4, 5, 6)[] == 6
    @test qa("{[a;b;c;d;e;f;g]g}", 1, 2, 3, 4, 5, 6, 7)[] == 7
    @test qa("{[a;b;c;d;e;f;g;h]h}", 1, 2, 3, 4, 5, 6, 7, 8)[] == 8
  end
end
@testset "server-side asarray" begin
  @test begin
      f = k(0, "{}")
      a = asarray(f)
      length(a) == 9 && unsafe_string(kS(a[2])[1]) == "x"
  end
  @test asarray(k(0, "*:"))[] == 3
  @test asarray(k(0, "*"))[] == 3
  @test asarray(k(0, "(/:)"))[] == 4
  @test (a = asarray(k(0, "{z}[10;20]")); asarray(a[2], false)[] == 10)
  @test (a = asarray(k(0, "('[sum;*])")); asarray(a[2], false)[] == 3)
  @testset "f<adverb>" for c in "'/\\"
      @test (a = asarray(k(0, "*$c")); asarray(a[], false)[] == 3)
      @test (a = asarray(k(0, "*$(c):")); asarray(a[], false)[] == 3)
  end
  @test (a = asarray(k(0, ".J.jl.init")); eltype(a) == Ptr{V_})
  @test cdtemp() do  # enum
    qa("`:a set `:sym?`a`b`c")
    qa("get`:a") == [0, 1, 2]
  end
  @test cdtemp() do  # nested
    qa("`:a set (1 2;3 4 5)")
    qa("get`:a") == [2, 5]  # breaks
  end
end

@testset "q commands" begin
  @test q`+`(1, 2) == 3
  @test q`til 3`() == q`til`(3) == [0, 1, 2]
  # TODO: @test_throws JuQ.KdbException q`1+`("")
  @test_throws JuQ.KdbException q`1+""`()
  @test_throws JuQ.KdbException q`.J.e`("nonexistent")
  let e = q`.J.e`
    @test (x = e("true"); eltype(x) == Bool && x == true)
    @test (x = e("0x12"); eltype(x) == UInt8 && x == 0x12)
    @test (x = e("Int16(1)"); eltype(x) == Int16 && x == 1)
    @test (x = e("1"); eltype(x) == Int && x == 1)
    @test (x = e("Int32(1)"); eltype(x) == Int32 && x == 1)
    @test (x = e("Int64(1)"); eltype(x) == Int64 && x == 1)
    @test (x = e("1.5"); eltype(x) == Float64 && x == 1.5)
    @test (x = e("Float32(1)"); eltype(x) == Float32 && x == 1)
  end
  @testset "q function calls" begin
    # using q``
    @test q`{x}`(1) == 1
    @test q`{y}`(1, 2) == 2
    @test q`{z}`(1, 2, 3) == 3
    @test q`{[a;b;c;d]d}`(1, 2, 3, 4) == 4
    @test q`{[a;b;c;d;e]e}`(1, 2, 3, 4, 5) == 5
    @test q`{[a;b;c;d;e;f]f}`(1, 2, 3, 4, 5, 6) == 6
    @test q`{[a;b;c;d;e;f;g]g}`(1, 2, 3, 4, 5, 6, 7) == 7
    @test q`{[a;b;c;d;e;f;g;h]h}`(1, 2, 3, 4, 5, 6, 7, 8) == 8
  end
end
