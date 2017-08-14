using DataFrames

struct K_Table  <: AbstractDataFrame
    o::K_Object
    function K_Table(o::K_Object)
        t = xt(o.x)
        if(t != XT)
            throw(ArgumentError("type mismatch: t=$t ≠ $XT"))
        end
        return new(o)
    end
    function K_Table(columns::Vector, colnames::Vector{Symbol})
        ncols = length(columns)
        x = K(colnames)
        kcols = map(x->r1(K(x).o.x), columns)
        y = knk(ncols, kcols...)
        o = K_Object(xT(xD(r1(x.o.x), y)))
        new(o)
    end
    function K_Table(; kwargs...)
        x = ktn(KS, 0)
        y = ktn(KK, 0)
        rx, ry = map(Ref{K_}, [x, y])
        for (k, v) in kwargs
            x = js(rx, ss(k))
            y = jk(ry, K_(v))
        end
        o = K_Object(xT(xD(x, y)))
        new(o)
    end
end

DataFrames.ncol(x::K_Table) = xn(xx(xk(x.o.x)))
DataFrames.nrow(x::K_Table) = xn(unsafe_load(Ptr{K_}(xy(xk(x.o.x))+16)))
DataFrames.index(x::K_Table) = DataFrames.Index(Array(K(xx(xk(x.o.x)))))
DataFrames.columns(x::K_Table) = K(xx(xk(x.o.x)))
cols(x::K_Table) = K(xx(xk(x.o.x)))
Base.getindex(x::K_Table, i::Integer) =
    K(r1(unsafe_load(Ptr{K_}(xy(xk(x.o.x))+16), i)))
Base.getindex(x::K_Table, i::Integer, j::Integer) = x[j][i]
