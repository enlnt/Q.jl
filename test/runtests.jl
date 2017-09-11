using Q
import Q: kpointer, ktypecode, asarray, K_new, K_None
using Q._k, Q._k.GOT_Q
using Base.Test
using Base.Dates.AbstractTime
using DataFrames

include("test-utils.jl")
const side = GOT_Q ? "server" : "client"

@testset "Q tests" begin
  include("lowlevel-tests.jl")
  include("refcount-tests.jl")
  include("atom-tests.jl")
  include("vector-tests.jl")
  include("text-tests.jl")
  include("list-tests.jl")
  include("table-tests.jl")
  include("key-table-tests.jl")
  include("parser-tests.jl")
  include("$side-tests.jl")
  include("repl-tests.jl")
end
