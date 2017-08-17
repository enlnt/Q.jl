# Conversions between Julia and q types for the JuQ module.
#########################################################################
const K_None = K_Other(K_Object(ktj(101, 0)))
Base.convert(::Type{K_}, x::K) = x.o.x
# Conversion fom the Vector of K's to K_
function Base.convert(::Type{K_}, v::Vector{K_Vector})
    const n = length(v)
    const x = ktn(KK, n)
    const p = pointer(x)
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
    o = K_Object(x)
    t = xt(x)
    if t < 0
        class = K_CLASS[-t]
        return class(o)
    elseif t == KC
        return K_Chars(o)
    elseif 0 <= t <= KS
        return K_Vector(o)
    elseif t == XT
        return K_Table(o)
    end
    return K_Other(o)
end
Base.convert(::Type{K}, x::K) = x
Base.convert(::Type{K}, x) = K(K_new(x))
Base.convert(::Type{String}, x::K_symbol) = String(Symbol(x))
function Base.convert(::Type{Array}, x::K_Object)
    p = x.x
    t = xt(p)
    n = xn(p)
    T = C_TYPE[t]
    a = zeros(T, n)
    unsafe_copy!(pointer(a), Ptr{T}(p+16), n)
    return a
end

function Base.convert(::Type{String}, x::K_Object)
   p = x.x
   t = xt(p)
   if (t == KC)
       return unsafe_string(Ptr{C_}(p+16), xn(p))
   end
   if (t == -KS)
       return unsafe_string(unsafe_load(Ptr{Ptr{C_}}(p+8)))
   end
   error("cannot convert")
end

Base.print(io::IO, x::K_boolean) = print(io, Bool(x) ? "1b" : "0b")
Base.show(io::IO, x::K_boolean) = print(io, x)
Base.print(io::IO, x::K_symbol) = print(io, Symbol(x))
