#include <julia.h>
#include <stdlib.h>
#include "k.h"
#if defined(__linux__)
#include "jl-lib.h"
#else
#define QJL_IMPORT_JULIA_LIBRARY do{}while(0)
#endif

ZK none;
ZJ eos = 0;
Z K1(qjl_init){
  K a, e;
  I argc, i, n; S* argv;
  P(xt!=KC,krr("type"));
  ja(&x, &eos);
  a = k(0, ".z.x", (K)0);
  argc = a->n + 1;
  argv = malloc(argc * sizeof(S*));
  argv[0] = strdup("julia");
  for (i = 1; i < argc; ++i) {
    n = (I)(e = kK(a)[i-1])->n;
    /* drop trailing @ from args */
    if (n > 0 && kC(e)[n-1] == '@') --n;
    argv[i] = malloc((n+1) * sizeof(S));
    memcpy(argv[i], kC(e), n);
    argv[i][n] = '\0';
  }
  /* Parse an argc/argv pair to extract general julia options, passing
     back out any arguments that should be passed on to the script. */
  jl_parse_opts(&argc, &argv);
  jl_init_with_image((S)kC(x), jl_get_default_sysimg_path());
  jl_set_ARGS(argc, argv);
  R r1(none);}

Z K1(qjl_eval){
  jl_value_t *v;
  P(xt!=KC,krr("type"));
  ja(&x, &eos);
  v = jl_eval_string((S)xC);
  if (jl_exception_occurred())
    R krr(ss((S)jl_typeof_str(jl_exception_occurred())));
    /* TODO: Add something like this:
        jl_call2(jl_get_function(jl_base_module, "showerror"),
                 jl_stderr_obj(),
                 jl_exception_occurred());
        jl_printf(jl_stderr_stream(), "\n");
    */
  if (v == jl_nothing)
    R r1(none);
  if (v == jl_false)
    R kb(0);
  if (v == jl_true)
    R kb(1);
  R kp((S)jl_typeof_str(v));
}

Z K1(qjl_atexit){
  P(xt!=-KI,krr("type"));
  jl_atexit_hook(xi);
  R r1(none);
}

K1(qjl){
  QJL_IMPORT_JULIA_LIBRARY;
  none = k(0, "::", (K)0);
  x = ktn(KS, 4);
  xS[0] = ss("");
  xS[1] = ss("init");
  xS[2] = ss("e");
  xS[3] = ss("atexit");
  R xD(x, knk(4, r1(none),
       dl(qjl_init, 1),
       dl(qjl_eval, 1),
       dl(qjl_atexit, 1)));}
