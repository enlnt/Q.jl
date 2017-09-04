using JuQ
import JuQ: kpointer
using JuQ._k, JuQ._k.GOT_Q
using Base.Test
using Base.Dates.AbstractTime
using DataFrames

include("test-utils.jl")
const side = GOT_Q ? "server" : "client"

@testset "JuQ tests" begin
  include("lowlevel-tests.jl")
  include("refcount-tests.jl")
  include("atom-tests.jl")
  include("vector-tests.jl")
  include("text-tests.jl")
  include("list-tests.jl")
  include("table-tests.jl")
  include("$side-tests.jl")
end
