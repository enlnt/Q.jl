newref(x) = K_Ref(K_new(x))
@testset "K_new" begin
  @test (x = newref(Int64(1)); (xt(x.x), xj(x.x)) == (-KJ, 1))
  @test (x = newref(Date(2000)); (xt(x.x), xi(x.x)) == (-KD, 0))
  @test (x = newref(DateTime(2000)); (xt(x.x), xj(x.x)) == (-KP, 0))
  @test (x = newref(Dates.Microsecond(2)); (xt(x.x), xj(x.x)) == (-KN, 2000))
end
struct TestType end
@testset "ktypecode(::Type) tests" begin
  @test_throws ErrorException ktypecode(TestType)
  @test ktypecode(Bool) == KB
  @test ktypecode(UInt128) == UU
  @test ktypecode(UInt8) == KG
  @test ktypecode(Int16) == KH
  @test ktypecode(Int32) == KI
  @test ktypecode(Int64) == KJ
  @test ktypecode(Float32) == KE
  @test ktypecode(Float64) == KF
  @test ktypecode(Char) == KC
  @test ktypecode(Symbol) == KS
  @test ktypecode(Q.TimeStamp) == KP
  @test ktypecode(Q.Month) == KM
  @test ktypecode(Q.Date) == KD
  @test ktypecode(Q.DateTimeF) == KZ
  @test ktypecode(Q.TimeSpan) == KN
  @test ktypecode(Q.Minute) == KU
  @test ktypecode(Q.Second) == KV
  @test ktypecode(Q.Time) == KT
end
