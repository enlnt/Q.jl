# Conversions between Julia and q types for the JuQ module.

#########################################################################
# Conversions of simple types (numbers and nothing)

# conversions from Julia types to K

const K_TYPE = Dict(Bool=>KB,
                    UInt8=>KG, Int16=>KH, Int32=>KI, Int64=>KJ,
                    Float32=>KE, Float64=>KF,
                    Char=>KC, Symbol=>KS)
const C_TYPE = Dict(KB=>Bool,
                    KG=>UInt8, KH=>Int16, KI=>Int32, KJ=>Int64,
                    KE=>Float32, KF=>Float64,
                    KC=>Char, KS=>Symbol)

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
    n = length(a)
    x = ktn(t, n)
    unsafe_copy!(Ptr{T}(x+16), pointer(a), n)
    return K_Vector{T}(K_Object(x))
end

Base.convert(::Type{S}, s::K_Scalar{T}) where {S<:Number, T<:S} =
    T(unsafe_load(Ptr{T}(s.o.x+8)))
Base.convert(::Type{String}, s::K_Scalar{Symbol}) =
    unsafe_string(unsafe_load(Ptr{S_}(s.o.x+8)))
Base.convert(::Type{Symbol}, x::K_Scalar{Symbol}) = Symbol(String(x))
Base.convert(::Type{Char}, x::K_Scalar{Char}) =
    Char(unsafe_load(Ptr{C_}(x.o.x+8)))
Base.string(x::K_Scalar{Symbol}) = String(x)
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
