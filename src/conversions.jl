# Conversions between Julia and q types for the JuQ module.
#########################################################################
const K_None = K_Other(ktj(101, 0))

Base.convert(::Type{String}, x::K_symbol) =
    unsafe_string(unsafe_load(pointer(x)))
Base.convert(::Type{Symbol}, x::K_char) = Symbol(Char(x))
Base.convert(::Type{String}, x::K_char) = unsafe_string(pointer(x), 1)

for T in (Int8, Int16, Int32, Int64, Int128, Float32, Float64)
    @eval Base.convert(::Type{$T}, x::_Signed) = $T(x.a[])
end

# Conversion from the Vector of K's to K_
function Base.convert(::Type{K_}, v::Vector{K_Vector})
    n = length(v)
    x = ktn(KK, n)
    p = pointer(x)
    for (i, vi) in enumerate(v)
        unsafe_store!(p, r1(vi.o.x), i)
    end
    return x
end
# Julia to K conversions
function Base.convert(::Type{K}, x::K_)
    if x == C_NULL
        return K_None
    end
    t = xt(x)
    if t == -EE
       	msg = xs(x)
        r0(x)
        throw(KdbException(msg))
    end
    if t < 0
        return K_Scalar(x)
    elseif 0 <= t <= KS
        return K_Vector(x)
    elseif t == XT
        return K_Table(x)
    end
    return K_Other(x)
end
Base.convert(::Type{K}, x::K) = x
Base.convert(::Type{K}, x) = K(K_new(x))

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
