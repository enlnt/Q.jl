export q
struct _Q
end

const q = _Q()

function (f::_Q)(cmd::String, args...)
    K(k(KDB_HANDLE[], cmd, map(K_new, args)...))
end
