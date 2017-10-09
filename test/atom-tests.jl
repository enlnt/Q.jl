@testset "atom tests" begin
  @testset "atom from low level" for (t, kx, K_x, v) in [
    (KB, kb, K_boolean, true),
    (UU, ku, K_guid, 0x0102030405060708090a0b0c0d0e0fa0),
    (KG, kg, K_byte, 0xAB),
    (KH, kh, K_short, H_(42)),
    (KI, ki, K_int, I_(42)),
    (KJ, kj, K_long, J_(42)),
    (KE, ke, K_real, 3.14f0),
    (KF, kf, K_float, 3.14),
    (KF, kf, K_float, 3.14),
    (KC, kc, K_char, G_('a')),
    (KS, ks, K_symbol, ss("symbol")),
    (KP, a->ktj(-KP, a), K_timestamp, J_(42)),
    (KM, a->ktj(-KM, a), K_month, I_(42)),
    (KD, kd, K_date, I_(42)),
    (KZ, kz, K_datetime, 365.25),
    (KN, a->ktj(-KN, a), K_timespan, J_(42)),
    (KU, a->ktj(-KU, a), K_minute, I_(42)),
    (KV, a->ktj(-KV, a), K_second, I_(42)),
    (KT, kt, K_time, I_(42)),
  ]
    let x = K(kx(v))
      @test x == K_x(v) == K_x(kx(v))  # XXX: Is the last form needed?
      @test x.a[] === v
      @test ktypecode(x) == xt(kpointer(x)) == -t
      @test xr(kpointer(x)) == 0
      @test_throws ArgumentError K_x(ktj(101, 0))
    end
  end
  @test K_char(1.) == UInt8(1.)
  @testset "atom supertypes" begin
    @test K_boolean <: Integer
    @test K_guid <: Unsigned
    @test K_short <: Signed
    @test K_int <: Signed
    @test K_long <: Signed
    @test K_float <: AbstractFloat
    @test K_real <: AbstractFloat
    @test K_date <: AbstractTime
    @test K_datetime <: AbstractTime
    @test K_timespan <: Dates.Period
    @test K_timestamp <: Dates.TimeType
    # instances
    @test K(false) isa Integer
    @test K(0x0102030405060708090a0b0c0d0e0fa0) isa Unsigned
    @test K(0x23) isa Unsigned
    @test K(Int16(0)) isa Signed
    @test K(Int32(0)) isa Signed
    @test K(Int64(0)) isa Signed
    @test K(0.0) isa Real
    @test K(Date(2000)) isa AbstractTime
  end
  @testset "atom from exotic" begin
    @test (x = K(BigInt(666)); ktypecode(x) == -KJ &&x == 666)
    @test (x = K(BigFloat(999)); ktypecode(x) == -KF &&x == 999)
  end
  @testset "atom roundtrip" for v in [
    true, false,
    0x0102030405060708090a0b0c0d0e0fa0,
    0x00, 0xAB,
    map(Int16, (1, 2, 3))...,
    map(Int32, (1, 2, 3))...,
    map(Int64, (1, 2, 3))...,
    1, 2, 3, 3.14f0, 3.14e0,
    # NB: Char type does not roundtrip.
    :a,  Date(2008, 8, 8), # TODO: Other temporal types.
  ]
    @test K(v)[] === v
  end
  @testset "atom get/set!" begin
    let x = K(1)
      @test (x.a[] = 2; x == x[] === 2)
      @test_throws MethodError x[] = 3
    end
    let x = K(:a)
      @test (x.a[] = ss(:b); x == x[] === :b)
    end
  end
  @testset "array methods on atoms" begin
    let x = K(1)
      @test size(x) === ()
      @test size(x, 1) === 1
      @test_throws BoundsError size(x, -1)
      @test ndims(x) === ndims(typeof(x)) === 0
      @test length(x) === endof(x) == 1
    end
  end
  @testset "atom arithmetics" begin
    @test K(1.) + 2. === 2. + K(1.)  === 3.
    @test K(1) + 2. === 2 + K(1.)  === 3.
    @test K(Float32(1)) + Int64(2) === 3.
    @test K(1) < K(2.) < 3
  end
  @testset "char print and show" begin
    @test string(K('a')) == "a"
    @test show_to_string(K('a')) == "K('a')"
    @test show_to_string(MIME"text/plain"(), K('a')) == "K('a')"
  end
  @testset "nothing" begin
    let x = K(nothing)
      @test ktypecode(x) == 101
      @test kpointer(x) === kpointer(K_None)
      @test x === K_None
      @test x != 0
    end
  end
  @testset "char" begin
    let x = K('a')
      @test Symbol(x) == :a
      @test String(x) == "a"
      @test Char(x) == 'a'
    end
  end
  @testset "compare" begin
    @test K(:a) < K(:b)
    @test K('a') < K('b')
    @test K(1) < K(2)
  end
  @testset "show" begin
    @test show_to_string(K) == "K"
  end
end
