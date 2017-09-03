@testset "text tests" begin
  @testset "text roundtrip" begin
    # Strings and symbols
    @test (s = "abc"; x = K(s); String(x) == s)
    @test (s = :abc; x = K(s); Symbol(x) == s && String(x) == String(s))
    @test (a = [:abc, :def]; x = K(a); Array(x) == a)
  end
  @testset "Scalar to string" begin
    @test string(K(42)) == "K(42)"
    @test string(K(:a)) == "a"
  end
end
