# Conversions between Julia and q types for the Q module.
#########################################################################
const K_None = K_Other(K_new(nothing))

Base.convert(::Type{String}, x::K_symbol) =
    unsafe_string(unsafe_load(pointer(x)))
Base.convert(::Type{Symbol}, x::K_char) = Symbol(Char(x))
Base.convert(::Type{String}, x::K_char) = unsafe_string(pointer(x), 1)

for T in (Int8, Int16, Int32, Int64, Int128, Float32, Float64)
    for S in (_Bool, _Signed, _Unsigned, _Float)
        @eval Base.convert(::Type{$T}, x::$S) = $T(x.a[])
    end
end

# Julia to K conversions
Base.convert(::Type{K}, ::Void) = K_None
function Base.convert(::Type{K}, x::K_)
    @assert x != C_NULL
    t = xt(x)
    if t == -EE
       	msg = xs(x)
        r0(x)
        throw(KdbException(msg))
    end
    if t < 0
        return K_Atom(x)
    elseif 0 <= t <= KT
        return K_Vector(x)
    elseif t == XT
        return K_Table(x)
    elseif t == XT && xt(xx(x)) == xt(xy(x))
    elseif t in (100, 104, 105, 112)
        return K_Lambda(x)
    end
    return K_Other(x)
end
Base.convert(::Type{K}, x) = convert(K, K_new(x))

Base.print(io::IO, x::K_boolean) = print(io, Bool(x) ? "1b" : "0b")
Base.show(io::IO, x::K_boolean) = print(io, x)
Base.print(io::IO, x::K_symbol) = print(io, Symbol(x))

"""
A helper method to convert error returns from k(..) or ee(..)
to a Julia exception.
"""
function _E(x)
    if xt(x) == -EE
        try
            throw(KdbException(xs(x)))
        finally
            r0(x)
        end
    end
    K(x)
end

# Numeric promotions
Base.convert(::Type{Float64}, x::K_real) = Float64(x.a[])
