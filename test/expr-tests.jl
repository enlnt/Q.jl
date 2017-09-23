@testset "expr conversions" begin
    @test K(:(a + b)) == q("(+;`a;`b)")
    @test K(:(a + b + c)) == q("(+;`a;(+;`b;`c))")
    @test K(:(a + b + c + d)) == q("(+;`a;(+;`b;(+;`c;`d)))")
    @test K(:(a + b * c)) == q("(+;`a;(*;`b;`c))")
    @test K(:(-a)) == K(:(neg(a))) == q("(neg;`a)")
    @test K(:(enlist(x))) == q("(enlist;`x)")
    @test K(:(enlist(a,b,c,d,e))) == q("(enlist;`a;`b;`c;`d;`e)")
end

@testset "expr eval" begin
    @test q("eval", :(til(5))) == Array(0:4)
    @test (q("eval", :(a = 42)); q("a") == 42)
    @test (r = q("eval", :(a=2;b=3)); r == q("b") == 3 && q("a") == 2)
end
