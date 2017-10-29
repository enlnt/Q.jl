using Base.Test
using Q._k
import Q: K_Ref
import Q._k: impl_dl, impl_dot
fun(x, y) = kj(xj(x) + xj(y))
@testset "impl" begin
    @test begin
        x = K_Ref(impl_dl(cfunction(fun, K_, (K_, K_)), 2))
        a = K_Ref(knk(2, kj(2), kj(3)))
        #r = K_Ref(dot_(x.x, a.x))
        #xj(r.x) == 5
        true
    end
    @test begin
        g = K_Ref(impl_dl(cfunction(fun, K_, (K_, K_)), 2))
        a = K_Ref(knk(2, kj(2), kj(3)))
        r = K_Ref(impl_dot(g.x, a.x))
        xj(r.x) == 5
    end
end
