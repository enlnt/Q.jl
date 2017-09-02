using DataFrames

struct K_Table  <: AbstractDataFrame
    a::Array{K_,0}
    function K_Table(x::K_)
        a = asarray(x)
        t = xt(x)
        if(t != XT)
            throw(ArgumentError("type mismatch: t=$t ≠ $XT"))
        end
        return new(a)
    end
    function K_Table(columns::Vector, colnames::Vector{Symbol})
        ncols = length(columns)
        x = K_new(colnames)
        y = K_new(columns)
        a = asarray(xT(xD(x, y)))
        new(a)
    end
    function K_Table(; kwargs...)
        x = ktn(KS, 0)
        y = ktn(KK, 0)
        rx, ry = map(Ref{K_}, [x, y])
        for (k, v) in kwargs
            x = js(rx, ss(k))
            y = jk(ry, K_new(v))
        end
        a = asarray(xT(xD(x, y)))
        new(a)
    end
end

DataFrames.ncol(x::K_Table) = xn(xx(x.a[]))
DataFrames.nrow(x::K_Table) = xn(unsafe_load(Ptr{K_}(xy(x.a[])+16)))
DataFrames.index(x::K_Table) = DataFrames.Index(Array(K(xx(x.a[]))))
DataFrames.columns(x::K_Table) = K(xx(x.a[]))
cols(x::K_Table) = K(xx(x.a[]))
Base.getindex(x::K_Table, i::Integer) =
    K(r1(unsafe_load(Ptr{K_}(xy(x.a[])+16), i)))
Base.getindex(x::K_Table, i::Integer, j::Integer) = x[j][i]
