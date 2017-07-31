# Conversions between Julia and q types for the JuQ module.

#########################################################################
# Conversions of simple types (numbers and nothing)

# conversions from Julia types to K

const K_TYPE = Dict(Bool=>KB,
                    Int16=>KH, Int32=>KI, Int64=>KJ,
                    Float32=>KE, Float64=>KF)
const C_TYPE = Dict(KB=>Bool,
                    KH=>Int16, KI=>Int32, KJ=>Int64,
                    KE=>Float32, KF=>Float64)

K(x::Bool) = K(kb(x))
K(x::Float32) = K(ke(x))
K(x::Float64) = K(kf(x))
function K(i::Integer)
    t = -K_TYPE[typeof(i)]
    x = ktj(t, i)
    return K(x)
end

function K{T}(a::Array{T,1})
    t = K_TYPE[T]
    n = length(a)
    x = ktn(t, n)
    unsafe_copy!(Ptr{T}(x+16), pointer(a), n)
    return K(x)
end

Base.convert(::Type{T}, x::K) where {T<:Number} =
    T(unsafe_load(Ptr{C_TYPE[-xt(x.x)]}(x.x+8)))

function Base.convert(::Type{Array}, x::K)
   p = x.x
   t = xt(p)
   n = xn(p)
   T = C_TYPE[t]
   a = zeros(T, n)
   unsafe_copy!(pointer(a), Ptr{T}(p+16), n)
   return a
end
