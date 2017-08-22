#include <julia.h>
#include <dlfcn.h>
#include "k.h"

#define DLF(v) do{S r;v##_p=(v##_t)dlsym(h,#v);\
                  P(!v,(r=(S)dlerror(),krr(r)));}while(0)
typedef void *DL;
typedef void (*jl_parse_opts_t)(int *argcp, char ***argvp);
typedef void (*jl_set_ARGS_t)(int argc, char **argv);
typedef void (*jl_init_t)(void);
typedef void (*jl_atexit_hook_t)(int);
typedef jl_value_t* (*jl_eval_string_t)(const char *);

Z jl_parse_opts_t jl_parse_opts_p;
Z jl_set_ARGS_t jl_set_ARGS_p;
Z jl_init_t jl_init_p;
Z jl_atexit_hook_t jl_atexit_hook_p;
Z jl_eval_string_t jl_eval_string_p;

ZJ eos = 0;

Z K1(J_init){
  K argk; /* abuse KS type for extra storage */
  I argc; S* argv;
  P(xt,krr("x type"));
  DO(xn,P(xK[i]->t!=KC,krr("x[i] type")));
  DO(xn,ja(xK+i,&eos));
  argk = ktn(KS, xn);
  argc = xn;
  argv = kS(argk);
  DO(xn,argv[i]=kC(xK[i]));
  /* Parse an argc/argv pair to extract general julia options, passing
     back out any arguments that should be passed on to the script. */
  jl_parse_opts_p(&argc, &argv);
  /* Set julia-level ARGS array */
  jl_set_ARGS_p(argc, argv);
  jl_init_p();
  r0(argk);
  R ktj(101,0);}
Z K1(J_atexit_hook){jl_atexit_hook_p(xi);R ktj(101,0);}
Z K1(J_eval_string){jl_eval_string_p((S)xC);R ktj(101,0);}

K1(jl){
  S er;DL h;P(xt!=KC||xC[xn-1],krr("type"));
  h=dlopen((S)xC,RTLD_NOW|RTLD_GLOBAL);
  er=(S)dlerror();P(!h,krr(er));
  x = ktn(KS, 3);
  
  DLF(jl_parse_opts);
  DLF(jl_set_ARGS);
  DLF(jl_init);
  DLF(jl_atexit_hook);
  DLF(jl_eval_string);

  xS[0] = ss("init");
  xS[1] = ss("eval_string");
  xS[2] = ss("atexit_hook");
  R xD(x,knk(3, dl(J_init,1),
             dl(J_eval_string,1),
	     dl(J_atexit_hook,1)));
}
