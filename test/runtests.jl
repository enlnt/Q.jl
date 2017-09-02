using JuQ
using JuQ._k, JuQ._k.GOT_Q
using Base.Test
using Base.Dates.AbstractTime
using DataFrames
include("utils.jl")
"""
  auto_r0 - a helper to test low level functions

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
  x = ktn(t, 0)
  res = (eltype(x) === typ
    && length(x) == 0
    && collect(x) == typ[])
  r0(x)
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
      fill!(a, ss("a"))
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
      @test (fill!(x, 42); collect(x)) == [42, 42, 42]
      @test (copy!(x, [1, 2, 3]); collect(x)) == [1, 2, 3]
    end
  end
  @testset "Vector extend" begin
    @xtest begin
      x = ktn(KS, 0)
      x = js(Ref{K_}(x), ss("a"))
      x= js(Ref{K_}(x), ss("b"))
      map(unsafe_string, x) == ["a", "b"]
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
    collect(x) == a
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

@testset "Low to high level - K(K_)" begin
  @test Bool(K(kb(1))) === true
  @test UInt8(K(kg(1))) == 1
  @test Int16(K(kh(1))) == 1
  @test Int32(K(ki(1))) == 1
  @test Int64(K(kj(1))) == 1
  @test Float32(K(ke(1.5))) == 1.5

  @test eltype(Array(K(ktn(KB, 0)))) === Bool
  @test eltype(Array(K(ktn(KG, 0)))) === UInt8
  @test eltype(Array(K(ktn(KH, 0)))) === Int16
  @test eltype(Array(K(ktn(KI, 0)))) === Int32
  @test eltype(Array(K(ktn(KJ, 0)))) === Int64
  @test eltype(Array(K(ktn(KE, 0)))) === Float32
  @test eltype(Array(K(ktn(KF, 0)))) === Float64

  @test String(K(kp("abc"))) == "abc"
end  # "Low to high level"

@testset "High level (K objects)" begin
  @test_throws ArgumentError K_char(kj(1))
  @testset "Scalar supertypes" begin
    @test K_boolean <: Integer
    @test K_guid <: Unsigned
    @test K_short <: Signed
    @test K_int <: Signed
    @test K_long <: Signed
    @test K_float <: AbstractFloat
    @test K_real <: AbstractFloat
    @test K_date <: AbstractTime
    # instances
    @test K(false) isa Integer
    @test K(0x0102030405060708090a0b0c0d0e0fa0) isa Unsigned
    @test K(0x23) isa Unsigned
    @test K(Int16(0)) isa Signed
    @test K(Int32(0)) isa Signed
    @test K(Int64(0)) isa Signed
    @test K(0.0) isa Real
  end
  @testset "Reference counting with K" begin
    @test begin
      x = K(1)
      auto_r0(K_new, x) do p
        xr(p) == 1
      end
    end
  end
  @testset "Typed scalar constructors" begin
    @test (x = K_short(0); eltype(x) === Int16)
    @test (x = K_int(0); eltype(x) === Int32)
  end
  @testset "Scalar get/set!" begin
    let x = K(1)
      @test (x.a[] = 2) == 2
      @test x.a[] === 2
    end
    let x = K(:a)
      @test (x.a[] = ss(:b); x.a[] === ss(:b))
    end
  end
  @testset "Array methods on scalars" begin
    let x = K(1)
      @test size(x) == ()
      @test size(x, 1) == 1
      @test_throws BoundsError size(x, -1)
      @test ndims(x) == 0
      @test length(x) == endof(x) == 1
    end
  end
  @testset "Vector constructors" begin
    @test K_Vector([1, 2]) == K([1, 2]) == [1, 2]
    @test K_Vector([:a, :b]) == K([:a, :b]) == [:a, :b]
    @test (x = K[]; eltype(x) == K)
    @test (x = K[1]; eltype(x) == Int && Array(x) == [1])
    @test (x = K[1, 2., 3]; eltype(x) == Float64 && Array(x) == [1, 2, 3])
    @test (x = K[1, ""]; eltype(x) == K && x[1] == 1)
  end
  @testset "Vector indexing" begin
    let x = K[1, 2]
      @test x[1] == 1
      @test_throws BoundsError x[3]
      @test_throws BoundsError x[0]
      @test (x[1] = 10; x[1] == 10)
      @test_throws BoundsError x[3] = 0
    end
  end
  @testset "Round trip" begin
    for T in NUMBER_TYPES
      a = [typemin(T), typemax(T), zero(T)]
      x = K(a)
      @test Array(x) == a
      for n in a
        x = K(n)
        @test T(x) == n
      end
    end
    # Strings and symbols
    let s = "abc", x = K(s)
      @test String(x) == s
    end
    let s = :abc, x = K(s)
      @test Symbol(x) == s
      @test String(x) == String(s)
    end
    let a = [:abc, :def], x = K(a)
      @test Array(x) == a
    end
  end
  @testset "Scalar to string" begin
    @test string(K(42)) == "K(42)"
    @test string(K(:a)) == "a"
  end
  @testset "K constructors" begin
    @test (x = K(true); unsafe_load(pointer(x)) === true)
    @test (x = K(0x42); unsafe_load(pointer(x)) === 0x42)
    @test (x = K(Int16(11)); unsafe_load(pointer(x)) === Int16(11))
    @test (x = K(Int32(11)); unsafe_load(pointer(x)) === Int32(11))
    @test (x = K(11); unsafe_load(pointer(x)) === 11)
    @test (x = K(Float32(11)); unsafe_load(pointer(x)) === Float32(11))
    @test (x = K(11.); unsafe_load(pointer(x)) === 11.)
    @test (x = K(:a); unsafe_string(unsafe_load(pointer(x))) == "a")
    @test (x = K('a'); x.a[] == UInt8('a'))
    @test (x = K("abc"); unsafe_string(pointer(x), 3) == "abc")
    # Vectors
    @test (x = K([1]); collect(x) == [1])
    @test (x = K([:a, :b]); collect(x) == [:a, :b])
    @test (x = K((1, 2.)); x[1] == 1 && x[2] == 2.)
    @test (x = K((1, [2, 3])); x[1] == 1 && x[2] == [2, 3])
  end
  @testset "Conversions" begin
    @test (x = K_boolean(1); Bool(x) == true)
    @test (u = U_(2)^128-1; x = K_guid(u); U_(x) == u)
    @test (x = K_byte(0xAB); UInt8(x) == 0xAB)
    @test (x = K_short(42); H_(x) == 42)
    @test (x = K_int(42); I_(x) == 42)
    @test (x = K_long(42); J_(x) == 42)
    @test (x = K_real(42); E_(x) == 42)
    @test (x = K_float(42); F_(x) == 42)
    @test (x = K_char('a'); Char(x) == 'a')
    @test (x = K_symbol(:a); Symbol(x) == :a)
  end
  @testset "Arithmetics" begin
    @test K(1.) + 2. === 2. + K(1.)  === 3.
    @test K(1) + 2. === 2 + K(1.)  === 3.
  end
  @testset "Vector operations" begin
    x = K[1]
    @test push!(x, 2) == [1, 2]
    @test copy!(x, [10, 20]) == [10, 20]
    @test fill!(x, 0) == [0, 0]
  end
end  # "High level"

@testset "Tables" begin
  let x = K_Table(a=[1, 2])
    @test x == K_Table(Any[[1,2]], [:a])
    @test ncol(x) == 1
    @test nrow(x) == 2
    @test DataFrames.columns(x) == [:a]
    @test DataFrames.index(x) == DataFrames.Index(Dict(:a=>1), Symbol[:a])
    @test x[1] == [1, 2]
    @test x[2,1] == 2
  end
end
if GOT_Q
  include("server-tests.jl")
else
  include("client-tests.jl")
end
