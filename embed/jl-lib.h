#include <dlfcn.h>


#define DLX(T,v) do{S r;jl_##v##_p=(T)dlsym(h,"jl_" #v);           \
                  P(!jl_##v##_p,(r=(S)dlerror(),krr(r)));}while(0)
#define DLF(v) DLX(jl_##v##_t,v)
#define DLV(v) DLX(jl_value_t**,v)
#define DLT(v) DLX(jl_datatype_t**,v)
#if defined(true)
#undef true
#undef false
#endif
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
DLF(eval_string);                  \
DLF(exception_occurred);           \
DLF(typeof_str);                   \
DLF(unbox_uint8);                  \
DLF(unbox_int16);                  \
DLF(unbox_int32);                  \
DLF(unbox_int64);                  \
DLF(unbox_float64);                \
DLF(unbox_float32);                \
DLV(true);                         \
DLV(false);                        \
DLV(nothing);                      \
DLT(float32_type);                 \
DLT(float64_type);                 \
DLT(uint8_type);                   \
DLT(int16_type);                   \
DLT(int32_type);                   \
DLT(int64_type)

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

typedef jl_value_t* (*jl_exception_occurred_t)(void);
Z jl_exception_occurred_t jl_exception_occurred_p;
#define jl_exception_occurred (*jl_exception_occurred_p)

typedef const char *(*jl_typeof_str_t)(jl_value_t *v);
Z jl_typeof_str_t jl_typeof_str_p;
#define jl_typeof_str (*jl_typeof_str_p)

typedef uint8_t (*jl_unbox_uint8_t)(jl_value_t *v);
Z jl_unbox_uint8_t jl_unbox_uint8_p;
#define jl_unbox_uint8 (*jl_unbox_uint8_p)

typedef int16_t (*jl_unbox_int16_t)(jl_value_t *v);
Z jl_unbox_int16_t jl_unbox_int16_p;
#define jl_unbox_int16 (*jl_unbox_int16_p)

typedef int32_t (*jl_unbox_int32_t)(jl_value_t *v);
Z jl_unbox_int32_t jl_unbox_int32_p;
#define jl_unbox_int32 (*jl_unbox_int32_p)

typedef int64_t (*jl_unbox_int64_t)(jl_value_t *v);
Z jl_unbox_int64_t jl_unbox_int64_p;
#define jl_unbox_int64 (*jl_unbox_int64_p)

typedef float (*jl_unbox_float32_t)(jl_value_t *v);
Z jl_unbox_float32_t jl_unbox_float32_p;
#define jl_unbox_float32 (*jl_unbox_float32_p)

typedef double (*jl_unbox_float64_t)(jl_value_t *v);
Z jl_unbox_float64_t jl_unbox_float64_p;
#define jl_unbox_float64 (*jl_unbox_float64_p)

Z jl_value_t **jl_false_p;
#define jl_false (*jl_false_p)
Z jl_value_t **jl_true_p;
#define jl_true (*jl_true_p)
Z jl_value_t **jl_nothing_p;
#define jl_nothing (*jl_nothing_p)

Z jl_datatype_t **jl_float32_type_p;
#define jl_float32_type (*jl_float32_type_p)
Z jl_datatype_t **jl_float64_type_p;
#define jl_float64_type (*jl_float64_type_p)
Z jl_datatype_t **jl_int16_type_p;
#define jl_int16_type (*jl_int16_type_p)
Z jl_datatype_t **jl_int32_type_p;
#define jl_int32_type (*jl_int32_type_p)
Z jl_datatype_t **jl_int64_type_p;
#define jl_int64_type (*jl_int64_type_p)
Z jl_datatype_t **jl_uint8_type_p;
#define jl_uint8_type (*jl_uint8_type_p)
