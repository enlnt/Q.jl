\d .J
Z:,[;"\000"]
q:$[#h:getenv`QHOME1;h,"/";getenv[`HOME],"/q/"],($.z.o),"/q"
q)jl:(`J 2:(`jl;1))Z lib:first system
   "julia -e 'println(Libdl.dlpath(\"libjulia\"))'"
q)e:{jl.eval_string Z x}
jl.init[{$[x like"-?@";-1_x;x]}'(,q),.z.x]
