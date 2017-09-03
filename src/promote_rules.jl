# TODO: These rules are incomplete - need to figure out how
# to mimic Julia's builtin promotion rules.
Base.promote_rule(::Type{K_real}, ::Type{Int64}) = Float64
Base.promote_rule(::Type{K_real}, ::Type{Int32}) = Float32

Base.promote_rule(::Type{K_float}, ::Type{Int64}) = Float64
Base.promote_rule(::Type{K_float}, ::Type{Int32}) = Float64

Base.promote_rule(::Type{K_long}, ::Type{Float64}) = Float64
Base.promote_rule(::Type{K_long}, ::Type{Int32}) = Int64

Base.promote_rule(::Type{K_int}, ::Type{Float64}) = Float64
Base.promote_rule(::Type{K_int}, ::Type{Int64}) = Int64

Base.promote_rule(::Type{K_short}, ::Type{Float64}) = Float64
Base.promote_rule(::Type{K_short}, ::Type{Int64}) = Int64
Base.promote_rule(::Type{K_short}, ::Type{Int32}) = Int32

# K - K rules
Base.promote_rule(::Type{K_float}, ::Type{K_float}) = Float64
Base.promote_rule(::Type{K_float}, ::Type{K_real}) = Float64
Base.promote_rule(::Type{K_float}, ::Type{K_int}) = Int64
Base.promote_rule(::Type{K_float}, ::Type{K_short}) = Int64
Base.promote_rule(::Type{K_float}, ::Type{K_boolean}) = Int64

Base.promote_rule(::Type{K_long}, ::Type{K_float}) = Float64
Base.promote_rule(::Type{K_long}, ::Type{K_real}) = Float64
Base.promote_rule(::Type{K_long}, ::Type{K_int}) = Int64
Base.promote_rule(::Type{K_long}, ::Type{K_short}) = Int64
Base.promote_rule(::Type{K_long}, ::Type{K_boolean}) = Int64
