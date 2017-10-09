@testset "vector tests" begin
  @testset "vector from low level" begin
    @test (x = K(ktn(KB, 0)); eltype(x) === Bool)
    @test (x = K(ktn(KG, 0)); eltype(x) === UInt8)
    @test (x = K(ktn(KH, 0)); eltype(x) === Int16)
    @test (x = K(ktn(KI, 0)); eltype(x) === Int32)
    @test (x = K(ktn(KJ, 0)); eltype(x) === Int64)
    @test (x = K(ktn(KE, 0)); eltype(x) === Float32)
    @test (x = K(ktn(KF, 0)); eltype(x) === Float64)
    @test (x = K(ktn(KC, 0)); eltype(x) === UInt8)
    @test (x = K(ktn(KS, 0)); eltype(x) === Symbol)
    @test (x = K(ktn(KD, 0)); eltype(x) === Date)
    @test_throws ArgumentError Q.K_Chars(ktn(KB,0))
    @test String(K(kp("abc"))) == "abc"
  end  # "vector from low level"
  @testset "vector constructors" begin
    @test K_Vector([1, 2]) == K([1, 2]) == K(1:2) == [1, 2]
    @test K_Vector([:a, :b]) == K([:a, :b]) == [:a, :b]
    @test (x = K[1]; eltype(x) == Int && Array(x) == [1])
    @test (x = K[1, 2., 3]; eltype(x) == Float64 && Array(x) == [1, 2, 3])
    @test K(["", ""]) == K["", ""]
    @test eltype(Q._vector(Int, 2)) == Int
  end
  @testset "vector indexing" begin
    let x = K[1, 2]
      @test x[1] === 1
      @test_throws BoundsError x[3]
      @test_throws BoundsError x[0]
      @test (x[1] = 10; x[1] === 10)
      @test_throws BoundsError x[3] = 0
    end
  end
  @testset "vector round trip" for T in NUMBER_TYPES
    a = [typemin(T), typemax(T), zero(T)]
    x = K(a)
    @test Array(x) == a
    for n in a
      x = K(n)
      @test T(x) == n
    end
    @test String(K("αβγ")) == "αβγ"
  end
  @testset "Vector operations" begin
    x = K[1]
    @test push!(x, 2) == [1, 2]
    @test copy!(x, [10, 20]) == [10, 20]
    @test fill!(x, 0) == [0, 0]
    @test append!(x, 1:2) == [0, 0, 1, 2]
    @test empty!(x) == Int[]
  end
  @testset "string print and show" begin
    @test string(K("αβγ"), K("δ")) == "αβγδ"
    @test show_to_string(K("δ")) == """K("δ")"""
    @test show_to_string(MIME"text/plain"(), K("δ")) == """K("δ")"""
  end
  @testset "temporal" begin
    @test (x = K[Date(2002)]; x[1] = Date(2000); x.a[1] == 0)
  end
end
