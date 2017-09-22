@testset "expr conversions" begin
    @test K(:(a + b)) == q("(+;`a;`b)")
    @test K(:(a + b * c)) == q("(+;`a;(*;`b;`c))")
    @test K(:(-a)) == K(:(neg(a))) == q("(neg;`a)")
end

@testset "expr eval" begin
    @test q("eval", :(til(5))) == Array(0:4)
end
