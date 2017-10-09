import Q: chkparens
@testset "parser" for (n, cmd) in [
   (0, "([{}])"),
   (-1, "([{}]"),
   (5,  "((([}])))"),
   (2, "(})"),
   (0, ""),
   (0, "q)42"),
]
   @test n == chkparens(cmd)
end
