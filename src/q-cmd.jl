export q, @q

const q = _Q()

function (f::_Q)(cmd::String, args...)
    x = k(KDB_HANDLE[], cmd, map(K_new, args)...)
    systemerror("k", x == C_NULL)
    K(x)
end

macro q(ex)
    :(q("eval", $(esc(K(ex)))))
end
