# Supertypes for atomic q types.
const SUPERTYPE = Dict(
    :_Bool     => Integer,
    :_Unsigned => Unsigned,
    :_Signed   => Signed,
    :_Float    => AbstractFloat,
    :_Text     => Any,
    :_Temporal => AbstractTime
)
K_CLASSES = Type[]
# Create a parametrized type for each type class.
for (class, super) in SUPERTYPE
    @eval begin
        export $class
        struct $class{t,CT,JT} <: $(super)
            a::Array{CT,0}
            function $class{t,CT,JT}(x::K_) where {t,CT,JT}
                a = asarray(x)
                t′ = xt(x)
                if t != -t′
                    throw(ArgumentError("type mismatch: t=$t, t′=$t′"))
                end
                new(a)
            end
        end
        Base.convert(::Type{$class{t,C,T}}, x::$class{t,C,T}) where {t,C,T} = x
        function Base.convert(::Type{$class{t,C,T}}, x::C) where {t,C,T}
            r = $class{t,C,T}(ka(-t))
            r.a[] = x
            r
        end
        function Base.convert(::Type{$class{t,C,T}}, x) where {t,C,T}
            r = $class{t,C,T}(ka(-t))
            r.a[] = _cast(C, T(x))::C
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
        Base.getindex(x::$class) = eltype(x)(x)
        Base.pointer(x::$class{t,CT,JT}) where {t,CT,JT} = pointer(x.a)
        Base.show(io::IO, x::$class{t,CT,JT}) where {t,CT,JT} = print(io,
            "K(", repr(JT(x.a[])), ")")
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
end
function K_Atom(x::K_)
    t = -xt(x)
    ti = typeinfo(t)
    K_CLASS[t]{t,ti.c_type,ti.jl_type}(x)
end
include("promote_rules.jl")
