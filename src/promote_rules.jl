
Base.promote_rule(::Type(K_int), ::Type{Int64}) = Int64
Base.promote_rule(::Type(K_short), ::Type{Int64}) = Int64
Base.promote_rule(::Type(K_short), ::Type{Int32}) = Int32
