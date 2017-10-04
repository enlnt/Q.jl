#include <dlfcn.h>


#define DLX(T,v) do{S r;jl_##v##_p=(T)dlsym(h,"jl_" #v);           \
                  P(!jl_##v##_p,(r=(S)dlerror(),krr(r)));}while(0)
#define DLF(v) DLX(jl_##v##_t,v)
#define DLV(v) DLX(jl_value_t**,v)
#define DLT(v) DLX(jl_datatype_t**,v)

#define QJL_IMPORT_JULIA_LIBRARY      \
S er;DL h;P(xt!=KC,krr("type"));      \
ja(&x, &eos);                         \
h=dlopen((S)xC,RTLD_NOW|RTLD_GLOBAL); \
er=(S)dlerror();P(!h,krr(er));        \
DLF(parse_opts);                   \
DLF(set_ARGS);                     \
DLF(init_with_image);              \
DLF(get_default_sysimg_path);      \
DLF(atexit_hook);                  \
DLF(eval_string)

typedef void *DL;

typedef void (*jl_parse_opts_t)(int *argcp, char ***argvp);
Z jl_parse_opts_t jl_parse_opts_p;
#define jl_parse_opts (*jl_parse_opts_p)

typedef void (*jl_set_ARGS_t)(int argc, char **argv);
Z jl_set_ARGS_t jl_set_ARGS_p;
#define jl_set_ARGS (*jl_set_ARGS_p)

typedef void (*jl_init_with_image_t)(const char *julia_home_dir,
                                     const char *image_relative_path);
Z jl_init_with_image_t jl_init_with_image_p;
#define jl_init_with_image (*jl_init_with_image_p)

typedef char* (*jl_get_default_sysimg_path_t)(void);
Z jl_get_default_sysimg_path_t jl_get_default_sysimg_path_p;
#define jl_get_default_sysimg_path (*jl_get_default_sysimg_path_p)

typedef void (*jl_atexit_hook_t)(int);
Z jl_atexit_hook_t jl_atexit_hook_p;
#define jl_atexit_hook (*jl_atexit_hook_p)

typedef jl_value_t* (*jl_eval_string_t)(const char *);
Z jl_eval_string_t jl_eval_string_p;
#define jl_eval_string (*jl_eval_string_p)
