using DataFrames

struct K_KeyTable  <: AbstractDataFrame
    a::Array{K_,1}
    function K_KeyTable(x::K_)
        a = asarray(x)
        t = xt(x)
        if(t != XD)
            throw(ArgumentError("type mismatch: t=$t ≠ $XT"))
        end
        t = xt(xx(x))
        if(t != XT)
            throw(ArgumentError("type mismatch: xx.t=$t ≠ $XT"))
        end
        t = xt(xy(x))
        if(t != XT)
            throw(ArgumentError("type mismatch: xy.t=$t ≠ $XT"))
        end
        new(a)
    end
end

function K_KeyTable(nkeys::Integer; kwargs...)
    x = K_Table(;kwargs[1:nkeys]...)
    y = K_Table(;kwargs[nkeys+1:end]...)
    K_KeyTable(xD(r1(kpointer(x)), r1(kpointer(y))))
end

kpointer(x::K_KeyTable) = K_(pointer(x.a)-16)
keyvalptr(x::K_KeyTable, i) = unsafe_load(Ptr{K_}(xy(xk(x.a[1]))+16), i)
valvalptr(x::K_KeyTable, i) = unsafe_load(Ptr{K_}(xy(xk(x.a[2]))+16), i)
nkey(x::K_KeyTable) = Int(xn(xx(xk(x.a[1]))))
nval(x::K_KeyTable) = Int(xn(xx(xk(x.a[2]))))
colnames(x::K_KeyTable) = [K(r1(xx(xk(x.a[1]))));
                           K(r1(xx(xk(x.a[2]))))]

Base.serialize(io::AbstractSerializer, x::K_KeyTable) =
    _serialize(io, x, typeof(x))

DataFrames.ncol(x::K_KeyTable) = nkey(x) + nval(x)
DataFrames.nrow(x::K_KeyTable) = Int(xn(keyvalptr(x, 1)))
DataFrames.index(x::K_KeyTable) = DataFrames.Index(Array(colnames(x)))

function Base.getindex(x::K_KeyTable, i::Integer)
    k = nkey(x)
    p = i <= k ? keyvalptr(x, i) : valvalptr(x, i - k)
    K(r1(p))
end
Base.getindex(x::K_KeyTable, i::Integer, j::Integer) = x[j][i]
Base.getindex(x::K_KeyTable, i::Symbol) = x[DataFrames.index(x)[i]]
