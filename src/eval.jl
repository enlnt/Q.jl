function _eval_string(x::K_)
    if xt(x) != KC
        return krr("type")
    end
    v = try
        eval(parse(xp(x)))
    catch err
        return krr(string(err))
    end
    p = try
        K_new(v)
    catch err
        return krr(string("K_new:", err))
    end
    p
end

const _eval_string_c = cfunction(_eval_string, K_, (K_, ))
