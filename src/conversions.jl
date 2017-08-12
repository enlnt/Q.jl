# Conversions between Julia and q types for the JuQ module.

#########################################################################
# Conversions of simple types (numbers and nothing)

# conversions from Julia types to K

const K_TYPE = Dict(Bool=>KB,
                    UInt8=>KG, Int16=>KH, Int32=>KI, Int64=>KJ,
                    Float32=>KE, Float64=>KF,
                    Char=>KC, Symbol=>KS, Cstring=>KS)
const K_None = K_Other(K_Object(ktj(101, 0)))
function Base.convert(::Type{K}, x::K_)
    if x == C_NULL
        return K_None
    end
    o = K_Object(x)
    t = xt(x)
    if (t < 0)
        return K_Scalar(o)
    elseif (t == KC)
        return K_Chars(o)
    elseif (0 <= t <= KS)
        return K_Vector(o)
    elseif (t == XT)
        return K_Table(o)
    end
    return K_Other(o)
end

Base.convert(::Type{K_}, x::Bool) = kb(x)
# TODO: guid
Base.convert(::Type{K_}, x::UInt8) = kg(x)
Base.convert(::Type{K_}, x::Int16) = kh(x)
Base.convert(::Type{K_}, x::Int32) = ki(x)
Base.convert(::Type{K_}, x::Int64) = kj(x)
Base.convert(::Type{K_}, x::Float32) = ke(x)
Base.convert(::Type{K_}, x::Float64) = kf(x)
Base.convert(::Type{K_}, x::Symbol) = ks(String(x))
Base.convert(::Type{K_}, x::Char) = kc(Int8(x))
Base.convert(::Type{K_}, x::String) = kp(x)
function Base.convert{T}(::Type{K_}, a::Vector{T})
    t = K_TYPE[T]
    CT = C_TYPE[t]
    n = length(a)
    x = ktn(t, n)
    unsafe_copy!(Ptr{T}(x+16), pointer(a), n)
    return x
end
function Base.convert(::Type{K_}, a::Vector{Symbol})
    t = KS
    CT = S_
    JT = Symbol
    n = length(a)
    x = ktn(t, n)
    for i in 1:n
        si = ss(a[i])
        unsafe_store!(Ptr{S_}(x+16), si, i)
    end
    return x
end
Base.convert(::Type{K}, x) = K(K_(x))
Base.convert(::Type{S}, s::K_Scalar{t,CT,JT}) where {S<:Number,t,CT,JT<:S} =
    JT(unsafe_load(Ptr{CT}(s.o.x+8)))
_K_symbol = K_Scalar{KS,S_,Symbol}  # Should we make defs like this public?

Base.convert(::Type{String}, s::_K_symbol) =
    unsafe_string(unsafe_load(Ptr{S_}(s.o.x+8)))
Base.convert(::Type{Symbol}, x::_K_symbol) = Symbol(String(x))
Base.string(x::_K_symbol) = String(x)
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

Base.print{t,CT,JT}(io::IO, x::K_Scalar{t,CT,JT}) = print(io, JT(x))
