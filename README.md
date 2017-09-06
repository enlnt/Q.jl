<a name="logo"/>
<div align="center">
<a href="https://enlnt.github.io/Q.jl/latest">
<img src="docs/src/juq-logo.png" alt="Q Logo" width="128.5" height="119"></img>
</a>
</div>

# Q.jl - Julia for kdb+
[![Build Status](https://travis-ci.org/enlnt/Q.jl.svg?branch=master)](https://travis-ci.org/enlnt/Q.jl)
[![codecov](https://codecov.io/gh/enlnt/Q.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/enlnt/Q.jl)
[![Coverage Status](https://coveralls.io/repos/github/enlnt/Q.jl/badge.svg?branch=master)](https://coveralls.io/github/enlnt/Q.jl?branch=master)
[![Latest Documentation](https://img.shields.io/badge/docs-latest-blue.svg)](https://enlnt.github.io/Q.jl/latest)

## Server side

```
q)J)println(42)
42
```

## Client side

With kdb+ running on a local port 8888:

```
julia> using Q
julia> hget(("localhost", 8888), "([]s:`a`b`c;a:11 22 33)")
3×2 Q.K_Table
│ Row │ s │ a  │
├─────┼───┼────┤
│ 1   │ a │ 11 │
│ 2   │ b │ 22 │
│ 3   │ c │ 33 │

julia> ans isa DataFrames.AbstractDataFrame
true
```
