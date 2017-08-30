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
end
