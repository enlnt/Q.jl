# TODO: These rules are incomplete - need to figure out how
# to mimic Julia's builtin promotion rules. 
Base.promote_rule(::Type{K_float}, ::Type{Int64}) = Float64

Base.promote_rule(::Type{K_long}, ::Type{Float64}) = Float64

Base.promote_rule(::Type{K_int}, ::Type{Float64}) = Float64
Base.promote_rule(::Type{K_int}, ::Type{Int64}) = Int64

Base.promote_rule(::Type{K_short}, ::Type{Float64}) = Float64
Base.promote_rule(::Type{K_short}, ::Type{Int64}) = Int64
Base.promote_rule(::Type{K_short}, ::Type{Int32}) = Int32
