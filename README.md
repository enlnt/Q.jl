# JuQ
[![Build Status](https://travis-ci.org/abalkin/JuQ.jl.svg?branch=master)](https://travis-ci.org/abalkin/JuQ.jl)
[![codecov](https://codecov.io/gh/abalkin/JuQ.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/abalkin/JuQ.jl)
[![Coverage Status](https://coveralls.io/repos/github/abalkin/JuQ.jl/badge.svg?branch=master)](https://coveralls.io/github/abalkin/JuQ.jl?branch=master)

## Server side

```
q)J)println(42)
42
```

## Client side

With kdb+ running on a local port 8888:

```
julia> using JuQ
julia> hget(("localhost", 8888), "([]s:`a`b`c;a:11 22 33)")
3×2 JuQ.K_Table
│ Row │ s │ a  │
├─────┼───┼────┤
│ 1   │ a │ 11 │
│ 2   │ b │ 22 │
│ 3   │ c │ 33 │

julia> ans isa DataFrames.AbstractDataFrame
true
```
