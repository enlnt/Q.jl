const DATE_SHIFT = -Dates.value(Date(2000))

struct TimeStamp <: Dates.TimeType
    x::Int64
    function TimeStamp(y::Int64, m::Int64=1, d::Int64=1,
                       h::Int64=0, mi::Int64=0, s::Int64=0,
                       ms::Int64=0, us::Int64=0, ns::Int64=0)
        err = Dates.validargs(DateTime, y, m, d, h, mi, s, ms)
        # TODO: Check us and ns
        isnull(err) || throw(unsafe_get(err))
        qdays = DATE_SHIFT + Dates.totaldays(y, m, d)
        new(ns + 10^3*us + 10^6*ms + 10^9 * (s + 60mi + 3600h + 86400qdays))
    end
    TimeStamp(::Type{Int}, x::Integer) = new(x)
end

TimeStamp(y, m=1, d=1, h=0, mi=0, s=0, ms=0, us=0, ns=0) = TimeStamp(Int64(y),
    Int64(m), Int64(d), Int64(h), Int64(mi), Int64(s),
    Int64(ms), Int64(us), Int64(ns))

_cast(::Type{TimeStamp}, x::Int64) = TimeStamp(Int, x)
Dates.value(x::TimeStamp) = x.x

struct TimeSpan <: Dates.TimePeriod
    value::Int64
end

Dates.value(x::TimeSpan) = x.value

TimeSpan(x::TimeSpan) = x
# TODO: Make this a q-style 0D... display.
Base.string(x::TimeSpan) = string("Q.TimeSpan($(x.value))")
_cast(::Type{Int64}, x::TimeSpan) = x.value
Dates.tons(x::TimeSpan) = x.value

struct DateTimeF <: Dates.TimeType
    x::Float64
end

for T in [:Month, :Minute, :Second, :Time]
    @eval begin
        struct $T <: Dates.TimeType
            x::Int32
            $T(::Type{Int}, x::Integer) = new(x)
        end
        Dates.value(x::$T) = x.x
        _cast(::Type{$T}, x::Int32) = $T(Int, x)
    end
end

# Constructors
# TODO: Add argument checking
Month(y, m=1) = Month(Int32(y), Int32(m))
Month(y::Int32, m::Int32=1) = Month(Int, Int32(12)*(y-Int32(2000)) + m - 1)

Minute(h, mi=0) = Minute(Int32(h), Int32(mi))
Minute(h::Int32, mi::Int32=0) = Minute(Int, Int32(60)*h + mi)

Second(h, mi=0, s=0) = Second(Int32(h), Int32(mi), Int32(s))
Second(h::Int32, mi::Int32=0, s::Int32=0) = Second(Int,
    Int32(60)*(Int32(60)*h + mi) + s)

Time(h, mi=0, s=0, ms=0) = Time(Int32(h), Int32(mi), Int32(s), Int32(ms))
Time(h::Int32, mi::Int32=0, s::Int32=0, ms::Int32=0) = Time(Int,
    10^3*(Int32(60)*(Int32(60)*h + mi) + s) + ms)

# Accessors
using Base.Dates.value
Dates.year(m::Month) = fld(Int32(24000)+value(m), Int32(12))
Dates.month(m::Month) = 1 + mod(value(m), Int32(12))
Dates.days(m::Month) = Dates.totaldays(Dates.year(m), Dates.month(m), 1)
Dates.days(t::TimeStamp) = fld(Dates.value(t), Int64(86400)*10^9) - DATE_SHIFT

let T = TimeStamp
    Dates.hour(t::T) = mod(fld(value(t), Int64(3600)*10^9), Int64(24))
    Dates.minute(t::T) = mod(fld(value(t), Int64(60)*10^9), Int64(60))
    Dates.second(t::T) = mod(fld(value(t), Int64(10^9)), Int64(60))
    Dates.millisecond(t::T) = mod(fld(value(t), Int64(10^6)), Int64(10^3))
    Dates.microsecond(t::T) = mod(fld(value(t), Int64(10^3)), Int64(10^3))
    Dates.nanosecond(t::T) = mod(value(t), Int64(10^3))
end

let T = Minute
    Dates.hour(t::T) = fld(value(t), Int32(60))
    Dates.minute(t::T) = mod(value(t), Int32(60))
    Dates.second(t::T) = Int32(0)
    Dates.millisecond(t::T) = Int32(0)
    Dates.microsecond(t::T) = Int32(0)
    Dates.nanosecond(t::T) = Int32(0)
end

let T = Second
    Dates.hour(t::T) = fld(value(t), Int32(3600))
    Dates.minute(t::T) = mod(fld(value(t), Int32(60)), Int32(60))
    Dates.second(t::T) = mod(value(t), Int32(60))
    Dates.millisecond(t::T) = Int32(0)
    Dates.microsecond(t::T) = Int32(0)
    Dates.nanosecond(t::T) = Int32(0)
end

let T = Time
    Dates.hour(t::T) = fld(value(t), Int32(3600*10^3))
    Dates.minute(t::T) = mod(fld(value(t), Int32(60*10^3)), Int32(60))
    Dates.second(t::T) = mod(fld(value(t), Int32(10^3)), Int32(60))
    Dates.millisecond(t::T) = mod(value(t), Int32(10^3))
    Dates.microsecond(t::T) = Int32(0)
    Dates.nanosecond(t::T) = Int32(0)
end

# Text representation

Base.string(x::TimeStamp) = string(Dates.format(x,
    dateformat"YYYY.mm.ddDHH:MM:SS.s", 32),
    @sprintf("%03d%03d", Dates.microsecond(x), Dates.nanosecond(x)))

function Base.show(io::IO, x::TimeStamp)
    Dates.format(io, x, dateformat"YYYY.mm.ddDHH:MM:SS.s")
    @printf(io, "%03d%03d", Dates.microsecond(x), Dates.nanosecond(x))
end

Dates.default_format(::Type{Month}) = dateformat"YYYY.mm\m"
Dates.default_format(::Type{Minute}) = dateformat"HH:MM"
Dates.default_format(::Type{Second}) = dateformat"HH:MM:SS"
Dates.default_format(::Type{Time}) = dateformat"HH:MM:SS.s"

for T in [:Month, :Minute, :Second, :Time]
    @eval begin
        Base.string(x::$T) = Dates.format(x, Dates.default_format($T))
        Base.show(io::IO, x::$T) = Dates.format(io, x, Dates.default_format($T))
    end
end
