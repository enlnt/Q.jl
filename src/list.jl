const K_List = K_Vector{TI0.number,K_,K}
Base.setindex!(x::K_List, el, i::Integer) = (r0(x.a[i]); x.a[i] = K_new(el))
function Base.push!(x::K_List, el)
    n′ = length(x) + 1
    a = K_new(el)
    p = K_(pointer(x)-16)
    p′ = jk(Ref{K_}(p), a)
    resetvector(x.a, n′, p′+16)
    x
end
function Base.append!(x::K_List, y::K_List)
    n′ = length(x) + length(y)
    px = K_(pointer(x)-16)
    py = K_(pointer(y)-16)
    p′ = jv(Ref{K_}(px), r1(py))
    resetvector(x.a, n′, p′+16)
    x
end
