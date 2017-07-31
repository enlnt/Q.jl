using JuQ
using JuQ.k
using Base.Test

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
  @testset "Scalar constructors" begin
    @test begin x = K(1); eltype(x) === Int64 && Number(x) == 1 end
  end
  @testset "Vector constructors" begin
    @test begin a = [1, 2]; x = K(a); Array(x) == a end
  end
end
