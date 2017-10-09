using Base.Dates.AbstractTime

# Supertypes for atomic q types.
const SUPERTYPE = Dict(
    :_Bool     => Integer,
    :_Unsigned => Unsigned,
    :_Signed   => Signed,
    :_Float    => AbstractFloat,
    :_Text     => Any,
    :_Time     => Dates.TimeType,
    :_Period   => Dates.TimePeriod,
)
K_CLASSES = Type[]
# Create a parametrized type for each type class.
for (class, super) in SUPERTYPE
    @eval begin
        export $class
        struct $class{t,C,T} <: $(super)
            a::Array{C,0}
            function $class{t,C,T}(x::K_) where {t,C,T}
                a = asarray(x)
                t′ = xt(x)
                if t != -t′
                    throw(ArgumentError("type mismatch: t=$t, t′=$t′"))
                end
                new(a)
            end
        end
        ktypecode(::Type{$class{t,C,T}}) where {t,C,T} = -t
        K_new(x::$class{t,C,T}) where {t,C,T} = r1(kpointer(x))
        Base.convert(::Type{$class{t,C,T}}, x::$class{t,C,T}) where {t,C,T} = x
        function Base.convert(::Type{$class{t,C,T}}, x::C) where {t,C,T}
            r = $class{t,C,T}(ka(-t))
            r.a[] = x
            r
        end
        function Base.convert(::Type{$class{t,C,T}}, x) where {t,C,T}
            r = $class{t,C,T}(ka(-t))
            tmp1 = T(x)::T
            tmp2 = _cast(C, tmp1)::C
            r.a[] = tmp2
            r
        end
        push!(K_CLASSES, $class)
        Base.size(::$class) = ()
        Base.size(x::$class, d) =
            convert(Int, d) < 1 ? throw(BoundsError()) : 1
        Base.ndims(x::$class) = 0
        Base.ndims(x::Type{$class}) = 0
        Base.length(x::$class) = 1
        Base.endof(x::$class) = 1
        # payload
        Base.eltype(::Type{$class{t,C,T}}) where {t,C,T} = T
        Base.eltype(x::$class) = eltype(typeof(x))
        Base.getindex(x::$class) = _cast(eltype(x), x.a[])
        Base.pointer(x::$class{t,C,T}) where {t,C,T} = pointer(x.a)
        Base.show(io::IO, x::$class{t,C,T}) where {t,C,T} = print(io,
            "K(", repr(_cast(T, x.a[])), ")")
        Base.serialize(io::AbstractSerializer, x::$class) =
            _serialize(io, x, typeof(x))
    end
end
@eval const K_Atom = Union{$(K_CLASSES...)}

K_CLASS = Dict{Int8,Type}()
# Aliases for concrete scalar types.
for ti in TYPE_INFO
    ktype = Symbol("K_", ti.name)
    class = ti.class
    T = ti.jl_type
    @eval begin
        export $ktype
        global const $ktype =
              $class{$(ti.number),$(ti.c_type),$T}
        K_CLASS[$(ti.number)] = $class
        # Display type aliases by name in REPL.
        Base.show(io::IO, ::Type{$ktype}) = print(io, $(string(ktype)))
        # Conversion to Julia types
        Base.convert(::Type{$T}, x::$ktype) = _cast($T, x.a[])
        Base.promote_rule(x::Type{$T}, y::Type{$ktype}) = x
        # Disambiguate T -> K type conversions
        #Base.convert(::Type{$ktype}, x::$ktype) = x
    end
    if ti.class in [:_Signed, :_Integer]
        @eval Base.dec(x::$ktype, pad::Int=1) =
            string(dec(x.a[], pad), $(ti.letter))
    elseif ti.class === :_Unsigned
        @eval Base.hex(x::$ktype, pad::Int=1, neg::Bool=false) =
            hex(x.a[], pad, neg)
    end
    if ti.number != KC
        @eval ktypecode(::Type{$ti.jl_type}) = $ti.number
    end
end
ktypecode(::Type{Char}) = KC

function K_Atom(x::K_)
    t = -xt(x)
    ti = typeinfo(t)
    K_CLASS[t]{t,ti.c_type,ti.jl_type}(x)
end
# Chars and symbols are special
Base.convert(Char, x::K_char) = Char(x.a[])
Base.print(io::IO, x::K_char) = print(io, Char(x))
Base.show(io::IO, x::K_char) = print(io, "K(", repr(Char(x)), ")")
Base.show(io::IO, ::MIME"text/plain", x::K_char) = show(io, x)
Base.hash(x::K_char, h::UInt) = hash(x.a[], h)
Base.hash(x::K_symbol, h::UInt) = hash(x.a[], h)

Symbol(x::K_symbol) = convert(Symbol, x)
#Base.print(io::IO, x::K_symbol) = print(io, Symbol(x))
Base.show(io::IO, x::K_symbol) = print(io, "K(", repr(Symbol(x)), ")")
Base.show(io::IO, ::MIME"text/plain", x::K_symbol) = show(io, x)

Base.convert(::Type{K_timespan}, x::Integer) = K_timespan(TimeSpan(x))

include("promote_rules.jl")
