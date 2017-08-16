using JuQ
using JuQ.k
using Base.Test
using JuQ.K_Object

NUMBER_TYPES = [UInt8, Int16, Int32, Int64, Float32, Float64]

function roundtrip_scalar(jk, kj, x)
    k = kj(x)
    r = jk(k)
    r0(k)
    return x == r
end

function empty_vector(t, typ)
  x = ktn(t, 0)
  res = (eltype(x) === typ
    && length(x) == 0
    && collect(x) == typ[])
  r0(x)
  return res
end
# Adds r0(x) to the end and runs @test
macro xtest(e::Expr)
  quote
    @test $(esc(Expr(:block, Expr(:(=), :r, e), :(r0(x)), :r)))
  end
end

@testset "Low level (k)" begin
  @testset "Reference counts" begin
    @xtest begin
      x = kj(0)
      n = [xr(x)]
      push!(n, xr(r1(x)))
      push!(n, xr(r0(x)))
      n == [0, 1, 0]
    end
  end
  @testset "Scalar constructors" begin
    @xtest (x = kb(1); xt(x) == -KB; xg(x) === G_(1))
    @xtest (x = kg(8); xt(x) == -KG; xg(x) === G_(8))
    @xtest (x = kh(100); xt(x) == -KH; xh(x) === H_(100))
    @xtest (x = ki(100); xt(x) == -KI; xi(x) === I_(100))
    @xtest (x = kj(100); xt(x) == -KJ; xj(x) === J_(100))
    @xtest (x = ke(1.5); xt(x) == -KE; xe(x) === E_(1.5))
    @xtest (x = kf(1.5); xt(x) == -KF; xf(x) === F_(1.5))
    @xtest (x = kc(10); xt(x) == -KC; xg(x) == G_(10))
    @xtest (x = ks("a"); xt(x) == -KS; xs(x) == "a")
  end
  @testset "Date conversions" begin
    @test ymd(2000, 1, 1) == 0
    @test dj(0) == 20000101
  end
  @testset "Scalar roundtrip" begin
    @test roundtrip_scalar(xg, kg, I_(42))
    @test roundtrip_scalar(xh, kh, I_(101))
    @test roundtrip_scalar(xi, ki, I_(10101))
    @test roundtrip_scalar(xj, kj, J_(1010101))
    @test roundtrip_scalar(xf, kf, F_(1e10))
    @test roundtrip_scalar(xs, ks, "abc")
  end
  @testset "Vector types" begin
    @test empty_vector(KB, G_)
    @test empty_vector(KG, G_)
    @test empty_vector(KH, H_)
    @test empty_vector(KI, I_)
    @test empty_vector(KJ, J_)
    @test empty_vector(KE, E_)
    @test empty_vector(KF, F_)
  end
  @testset "Vector ops" begin
    let o = K_Object(ktn(KJ, 3)), x = o.x
      @test eltype(x) === J_
      @test length(x) == 3
      @test (fill!(x, 42); collect(x)) == [42, 42, 42]
      @test (copy!(x, [1, 2, 3]); collect(x)) == [1, 2, 3]
    end
  end
  @testset "Vector extend" begin
    @xtest begin
      x = ktn(KS, 0)
      x = js(Ref{K_}(x), ss("a"))
      x= js(Ref{K_}(x), ss("b"))
      map(unsafe_string, x) == ["a", "b"]
    end
    @xtest begin
      x = ktn(KK, 0)
      x = jk(Ref{K_}(x), ktn(0, 0))
      x = jk(Ref{K_}(x), ktn(0, 0))
      xn(x) == 2
    end
  end
end
@testset "Low to high level - K(K_)" begin
  @test Number(K(kb(1))) === true
  @test Number(K(kg(1))) == 1
  @test Number(K(kh(1))) == 1
  @test Number(K(ki(1))) == 1
  @test Number(K(kj(1))) == 1
  @test Number(K(ke(1.5))) == 1.5

  @test eltype(Array(K(ktn(KB, 0)))) === Bool
  @test eltype(Array(K(ktn(KG, 0)))) === UInt8
  @test eltype(Array(K(ktn(KH, 0)))) === Int16
  @test eltype(Array(K(ktn(KI, 0)))) === Int32
  @test eltype(Array(K(ktn(KJ, 0)))) === Int64
  @test eltype(Array(K(ktn(KE, 0)))) === Float32
  @test eltype(Array(K(ktn(KF, 0)))) === Float64

  @test String(K(kp("abc"))) == "abc"
end
@testset "High level (K objects)" begin
  @testset "Vector constructors" begin
    @test (x = K[]; eltype(x) == K)
    @test (x = K[1]; eltype(x) == Int64 && Array(x) == [1])
    @test (x = K[1, 2., 3]; eltype(x) == Float64 && Array(x) == [1, 2, 3])
  end
  @testset "Round trip" begin
    for T in NUMBER_TYPES
      a = [typemin(T), typemax(T), zero(T)]
      x = K(a)
      @test Array(x) == a
      for n in a
        x = K(n)
        @test Number(x) == n
      end
    end
    # Strings and symbols
    let s = "abc", x = K(s)
      @test String(x) == s
    end
    let s = :abc, x = K(s)
      @test Symbol(x) == s
      @test String(x) == String(s)
    end
    let a = [:abc, :def], x = K(a)
      @test Array(x) == a
    end
    @testset "Scalar to string" begin
      @test string(K(42)) == "42"
      @test string(K(:a)) == "a"
    end
    @testset "K constructors" begin
      @test (x = K(true); unsafe_load(pointer(x)) === 0x01)
      @test (x = K(0x42); unsafe_load(pointer(x)) === 0x42)
      @test (x = K(Int16(11)); unsafe_load(pointer(x)) === Int16(11))
      @test (x = K(Int32(11)); unsafe_load(pointer(x)) === Int32(11))
      @test (x = K(11); unsafe_load(pointer(x)) === 11)
      @test (x = K(Float32(11)); unsafe_load(pointer(x)) === Float32(11))
      @test (x = K(11.); unsafe_load(pointer(x)) === 11.)
      @test (x = K(:a); unsafe_string(unsafe_load(pointer(x))) == "a")
      @test (x = K("abc"); unsafe_string(pointer(x), 3) == "abc")
    end
  end
end
