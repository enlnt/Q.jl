\d .J
Z:,[;"\000"]
q)jl:(`J 2:(`jl;1))Z lib:first system
   "julia -e 'println(Libdl.dlpath(\"libjulia\"))'"
q)e:{jl.eval_string Z x}
jl.init[]
