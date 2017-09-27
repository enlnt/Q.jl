struct K_Mark end

function _serialize(io::AbstractSerializer, x, T::Type)
    Base.serialize_type(io, K_Mark)
    serialize(io, T)
    # 3 - unenumerate, compress, allow serialization of timespan and timestamp
    b = K(b9(3, kpointer(x)))
    # TODO: Store count+bytes instead of serializing a vector.
    serialize(io, b.a)
end

function Base.deserialize(io::AbstractSerializer, ::Type{K_Mark})
    T = deserialize(io)
    b = K(deserialize(io))
    T(d9(kpointer(b)))
end
