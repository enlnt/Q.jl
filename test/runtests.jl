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
  end
end
