struct K_Mark end

function _serialize(s::AbstractSerializer, x, T::Type)
    Base.serialize_type(s, K_Mark)
    serialize(s, T)
    # 3 - unenumerate, compress, allow serialization of timespan and timestamp
    b = K(b9(3, kpointer(x)))
    write(s.io, Int64(length(b)))
    write(s.io, b.a)
end

function Base.deserialize(s::AbstractSerializer, ::Type{K_Mark})
    T = deserialize(s)
    n = read(s.io, Int64)
    b = _vector(KG, n)
    readbytes!(s.io, b)
    T(d9(kpointer(b)))
end
