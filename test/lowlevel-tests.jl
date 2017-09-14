"""
    auto_r0(f, g, a...)

Create a K_ object and call f on it before finalizing it with r0.

  Usage:

  ```julia
  @test auto_r0(kj, 42) do x
    # work with x
  end
  ```
"""
function auto_r0(f, g, a...)
  x = g(a...)
  try
    return f(x)
  finally
    r0(x)
  end
end

NUMBER_TYPES = [UInt8, Int16, Int32, Int64, Float32, Float64]

function roundtrip_scalar(jk, kj, x)
    k = kj(x)
    r = jk(k)
    r0(k)
    return x == r
end

function empty_vector(t, typ)
  x = asarray(ktn(t, 0))
  res = (eltype(x) === typ
    && length(x) == 0
    && collect(x) == typ[])
  return res
end
# Adds r0(x) to the end and runs @test
macro xtest(e::Expr)
  quote
    @test $(esc(Expr(:block, Expr(:(=), :r, e), :(r0(x)), :r)))
  end
end

@testset "Low level (_k)" begin
  @testset "Type names" begin
    @test string(K_) == "K_"
    # @test string(K) == "K"
    @test string(K_short) == "K_short"
  end
  @testset "Reference counts" begin
    @xtest begin
      x = kj(0)
      n = [xr(x)]
      push!(n, xr(r1(x)))
      r0(x)
      push!(n, xr(x))
      n == [0, 1, 0]
    end
    @xtest begin
      x = kj(0)
      y = K_new(x)
      n = xr(y)
      r0(y)
      x === y && n == 1
    end
    @test begin
      x = K_Ref(kj(666))
      y = K_Ref(r1(x.x))
      finalize(x)
      xr(y.x) == 0
    end
  end
  @testset "Scalar constructors" begin
    @xtest (x = kb(1); xt(x) == -KB && xg(x) === G_(1))
    @xtest (x = kg(8); xt(x) == -KG && xg(x) === G_(8))
    @xtest (x = kh(100); xt(x) == -KH && xh(x) === H_(100))
    @xtest (x = ki(100); xt(x) == -KI && xi(x) === I_(100))
    @xtest (x = kj(100); xt(x) == -KJ && xj(x) === J_(100))
    @xtest (x = ke(1.5); xt(x) == -KE && xe(x) === E_(1.5))
    @xtest (x = kf(1.5); xt(x) == -KF && xf(x) === F_(1.5))
    @xtest (x = kc(10); xt(x) == -KC && xg(x) == G_(10))
    @xtest (x = ks("a"); xt(x) == -KS && xs(x) == "a")
    @test auto_r0(ktj, I_(101), I_(0)) do x
      xt(x) == 101 && xj(x) == 0
    end
  end
  @testset "Interning" begin
    @test (x = sn("abcd", 3); unsafe_string(x) == "abc")
    @test (x = sn("abcd", 2); x === ss("ab"))
  end
  @testset "Date conversions" begin
    @test ymd(2000, 1, 1) == 0
    @test ymd(1970, 1, 1) == -10957
    @test ymd(2017, 1, 1) == 6210
    @test dj(0) == 20000101
    @test dj(-10957) == 19700101
    @test dj(6210) == 20170101
  end
  @testset "Scalar roundtrip" begin
    @test roundtrip_scalar(xg, kg, I_(42))
    @test roundtrip_scalar(xh, kh, I_(101))
    @test roundtrip_scalar(xi, ki, I_(10101))
    @test roundtrip_scalar(xj, kj, J_(1010101))
    @test roundtrip_scalar(xf, kf, F_(1e10))
    @test roundtrip_scalar(xs, ks, "abc")
  end
  @testset "Vector types" begin
    @test empty_vector(KB, B_)
    @test empty_vector(KG, G_)
    @test empty_vector(KH, H_)
    @test empty_vector(KI, I_)
    @test empty_vector(KJ, J_)
    @test empty_vector(KE, E_)
    @test empty_vector(KF, F_)
  end
  @testset "Vector accessors S" begin
    auto_r0(ktn, KS, 5) do x
      @test x|>n == 5
      @test x|>t == KS
      @test (a = kS(x); a[:] = s = ss("a"); a[2:4] == [s, s, s])
    end
  end
  @testset "Vector accessors K" begin
    auto_r0(ktn, KK, 5) do x
      @test x|>n == 5
      @test x|>t == KK
      @test begin
        a = kK(x)
        a[:] = k = ktj(101, 0)
        map(r1, a[2:end])
        a[2:4] == [k, k, k]
      end
    end
  end
  @testset "Vector accessors 2" for T in "GHIJEFC"
    t_, f_ = map(eval, [Symbol("K", T), Symbol("k", T)])
    auto_r0(ktn, t_, 5) do x
      @test x|>n == 5
      @test x|>t == t_
      @test (a = f_(x); a[:] = 1:5; a[2:4] == [2, 3, 4])
    end
  end
  @testset "Mixed types list" begin
    @xtest begin
      x = knk(3, kb(I_(0)), ku(U_(10)), ku(0))
      xn(x) == 3
    end
  end
  @testset "Table and dict" begin
    @xtest begin
      a = ktn(KI, 0)
      b = ktn(KJ, 0)
      x = xD(a, b)
      xx(x) === a && xy(x) == b
    end
    @xtest begin
      a = ktn(KS, 1)
      fill!(asarray(a, false), ss("a"))
      b = knk(1, ktn(KJ, 0))
      d = xD(a, b)
      x = xT(d)
      xk(x) === d
    end
  end
  @testset "Vector ops" begin
    let x = K(ktn(KJ, 3))
      @test eltype(x) === J_
      @test length(x) == 3
      @test fill!(x, 42) == [42, 42, 42]
      @test copy!(x, [1, 2, 3]) == [1, 2, 3]
    end
  end
  @testset "Vector extend" begin
    @xtest begin
      x = ktn(KS, 0)
      x = js(Ref{K_}(x), ss("a"))
      x= js(Ref{K_}(x), ss("b"))
      map(unsafe_string, asarray(x, false)) == ["a", "b"]
    end
    @xtest begin
      x = ktn(KK, 0)
      x = jk(Ref{K_}(x), ktn(0, 0))
      x = jk(Ref{K_}(x), ktn(0, 0))
      xn(x) == 2
    end
  end
  @testset "Serializarion/deserialization" begin
    @test auto_r0(kj, 42) do x
      s = b9(0, x)
      y = d9(s)
      try
        return okx(s) == 1 && xj(y)== xj(x)
      finally
        r0(s)
        r0(y)
      end
    end
  end
  @testset "communications" begin
    server() do port
      let h = khp("", port)
        @test h > 0
        # XXX: On the server, the first call to k(h, ..) gets
        # 'rcv. OS reports: Resource temporarily unavailable.
        # TODO: Figure out a cause and write a robust "hget".
        # Q.GOT_Q && r0(ee(k(h, "666")))
        # @test 666 == auto_r0(k, h, "666") do x
        #  xj(x)
        # end
      end
    end
  end
end  # "Low level"


@testset "asarray" begin
  @test begin
    a = asarray(kj(42))
    a[] == 42
  end
  @test begin
    x = ktn(KJ, 5)
    a = asarray(x)
    a[:] = 1:5
    kJ(x) == a
  end
  @test begin
    n = 0x0102030405060708090a0b0c0d0e0f10
    x = ku(n)
    a = asarray(x)
    a[] == n
  end
  @test begin
    d = xD(ktn(KJ, 0), ktn(KS, 0))
    a = asarray(d)
    x, y = a
    asarray(x, false) == asarray(y, false) == []
  end
  @test begin
    d = xD(ktn(KS, 2), knk(2, ktn(KJ, 3), ktn(KF, 3)))
    a = asarray(d)
    k, v = a
    asarray(k, false)[:] = map(ss, ["a", "b"])
    c1 = asarray(v, false)[1]
    c2 = asarray(v, false)[2]
    asarray(c1, false)[:] = 1:3
    asarray(c2, false)[:] = 3.14
    table = xT(r1(d))
    b = asarray(table)
    b[] == d
  end
  @test (a = asarray(K_new(nothing)); a[] == 0)
end
