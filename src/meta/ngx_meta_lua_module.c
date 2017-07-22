#include <ngx_meta_lua_module.h>


static ngx_core_module_t  ngx_meta_lua_module_ctx = {
    ngx_string("meta_lua"),
    NULL,
    NULL
};

ngx_module_t  ngx_meta_lua_module = {
    NGX_MODULE_V1,
    &ngx_meta_lua_module_ctx,              /* module context */
    NULL,                                  /* module directives */
    NGX_CORE_MODULE,                       /* module type */
    NULL,                                  /* init master */
    NULL,                                  /* init module */
    NULL,                                  /* init process */
    NULL,                                  /* init thread */
    NULL,                                  /* exit thread */
    NULL,                                  /* exit process */
    NULL,                                  /* exit master */
    NGX_MODULE_V1_PADDING
};
