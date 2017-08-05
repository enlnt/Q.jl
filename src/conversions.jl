# Conversions between Julia and q types for the JuQ module.

#########################################################################
# Conversions of simple types (numbers and nothing)

# conversions from Julia types to K

const K_TYPE = Dict(Bool=>KB,
                    UInt8=>KG, Int16=>KH, Int32=>KI, Int64=>KJ,
                    Float32=>KE, Float64=>KF,
                    Char=>KC, Symbol=>KS, Cstring=>KS)

function K(x::K_Ptr)
    o = K_Object(x)
    t = xt(x)
    if (t < 0)
        return K_Scalar(o)
    elseif (t == KC)
        return K_Chars(o)
    elseif (0 < t <= KS)
        return K_Vector(o)
    end
    return K_Other(o)
end

K(x::Bool) = K_Scalar(K_Object(kb(x)))
K(x::Float32) = K_Scalar(K_Object(ke(x)))
K(x::Float64) = K_Scalar(K_Object(kf(x)))

function K(i::Integer)
    t = -K_TYPE[typeof(i)]
    x = ktj(t, i)
    return K_Scalar(K_Object(x))
end
K(x::Symbol) = K_Scalar(K_Object(ks(String(x))))
K(x::Char) = K_Scalar(K_Object(kc(Int8(x))))
K(x::String) = K_Chars(K_Object(kp(x)))
function K{T}(a::Array{T,1})
    t = K_TYPE[T]
    CT = C_TYPE[t]
    n = length(a)
    x = ktn(t, n)
    unsafe_copy!(Ptr{T}(x+16), pointer(a), n)
    return K_Vector{t,CT,T}(K_Object(x))
end
function K(a::Vector{Symbol})
    t = KS
    CT = S_
    JT = Symbol
    n = length(a)
    x = ktn(t, n)
    for i in 1:n
        si = ss(a[i])
        unsafe_store!(Ptr{S_}(x+16), si, i)
    end
    return K_Vector{t,CT,JT}(K_Object(x))
end

Base.convert(::Type{S}, s::K_Scalar{T}) where {S<:Number, T<:S} =
    T(unsafe_load(Ptr{T}(s.o.x+8)))
Base.convert(::Type{String}, s::K_Scalar{Cstring}) =
    unsafe_string(unsafe_load(Ptr{S_}(s.o.x+8)))
Base.convert(::Type{Symbol}, x::K_Scalar{Cstring}) = Symbol(String(x))
Base.convert(::Type{Char}, x::K_Scalar{Char}) =
    Char(unsafe_load(Ptr{C_}(x.o.x+8)))
Base.string(x::K_Scalar{Cstring}) = String(x)
Base.convert(::Type{String}, s::K_Chars) =
    unsafe_string(Ptr{C_}(s.o.x+16), xn(s.o.x))
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
