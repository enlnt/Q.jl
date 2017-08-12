#include <julia.h>
#include <dlfcn.h>
#include "k.h"

#define DLF(v) do{S r;v##_p=(v##_t)dlsym(h,#v);\
                  P(!v,(r=(S)dlerror(),krr(r)));}while(0)
typedef void *DL;
typedef void (*jl_init_t)(void);
typedef void (*jl_atexit_hook_t)(int);
typedef jl_value_t* (*jl_eval_string_t)(const char *);

Z jl_init_t jl_init_p;
Z jl_atexit_hook_t jl_atexit_hook_p;
Z jl_eval_string_t jl_eval_string_p;

Z K1(init){jl_init_p();R r1(x);}
Z K1(atexit_hook){jl_atexit_hook_p(xi);R ktj(101,0);}
Z K1(eval_string){jl_eval_string_p((S)xC);R ktj(101,0);}

K1(jl){
  S er;DL h;P(xt!=KC||xC[xn-1],krr("type"));
  h=dlopen((S)xC,RTLD_NOW|RTLD_GLOBAL);
  er=(S)dlerror();P(!h,krr(er));
  x = ktn(KS, 3);
  
  DLF(jl_init);
  DLF(jl_atexit_hook);
  DLF(jl_eval_string);

  xS[0] = ss("init");
  xS[1] = ss("eval_string");
  xS[2] = ss("atexit_hook");
  R xD(x,knk(3, dl(init,1),
             dl(eval_string,1),
	     dl(atexit_hook,1)));
}
