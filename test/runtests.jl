using JuQ
using JuQ.k
using Base.Test

NUMBER_TYPES = [Bool, UInt8, Int16, Int32, Int64, Float32, Float64]

function roundtrip_scalar(jk, kj, x)
    k = kj(x)
    r = jk(k)
    r0(k)
    return x == r
end

@testset "Low level (k)" begin
  @testset "Scalar roundtrip" begin
    @test roundtrip_scalar(xg, kg, I_(42))
    @test roundtrip_scalar(xh, kh, I_(101))
    @test roundtrip_scalar(xi, ki, I_(10101))
    @test roundtrip_scalar(xj, kj, J_(1010101))
    @test roundtrip_scalar(xf, kf, F_(1e10))
    @test roundtrip_scalar(xs, ks, "abc")
  end
  @testset "Vector types" begin
    @test eltype(ktn(KH, 0)) === Int16
  end
end
@testset "Low to high level - K(K_Ptr)" begin
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
  end
end
