struct TimeStamp <: Dates.TimeType
    x::Int64
end

struct TimeSpan <: Dates.TimePeriod
    value::Int64
end
TimeSpan(x::TimeSpan) = x
# TODO: Make this a q-style 0D... display.
Base.string(x::TimeSpan) = string("Q.TimeSpan($(x.value))")
_cast(::Type{Int64}, x::TimeSpan) = x.value
Dates.tons(x::TimeSpan) = x.value

struct DateTimeF <: Dates.TimeType
    x::Float64
end

for T in [:Month, :Minute, :Second, :TimeMS]
    @eval struct $T <: Dates.TimeType
        x::Int32
    end
end
