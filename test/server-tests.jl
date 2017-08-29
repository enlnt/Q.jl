@testset "q commands" begin
  @test q`+`(1, 2) == 3
  @test q`til 3`() == q`til`(3) == [0, 1, 2]
  # TODO: @test_throws JuQ.KdbException q`1+`("")
  @test_throws JuQ.KdbException q`1+""`
  @test_throws JuQ.KdbException q`.J.e`("nonexistent")
end
