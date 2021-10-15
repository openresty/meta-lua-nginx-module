
/*
 * Copyright (C) Yichun Zhang (agentzh)
 */


#ifndef _NGX_META_LUA_H_INCLUDED_
#define _NGX_META_LUA_H_INCLUDED_


#include "ngx_meta_lua_api.h"


#define NGX_META_LUA_MODULE      0x41554c4d   /* "MLUA" */
#define NGX_META_LUA_CONF        0x02000000


#define ngx_meta_lua_conf_get_main_conf(cf)                                  \
    ((ngx_meta_lua_conf_t *) ngx_get_conf(cf->cycle->conf_ctx,               \
                                          ngx_meta_lua_module))

#define ngx_meta_lua_cycle_get_main_conf(cycle)                              \
    ((ngx_meta_lua_conf_t *) ngx_get_conf(cycle->conf_ctx,                   \
                                          ngx_meta_lua_module))


typedef struct {
    ngx_uint_t                   shm_zones_inited;
    ngx_array_t                 *shdict_zones;
    ngx_array_t                 *init_handlers;
    unsigned                     delay_init_handlers:1;
    unsigned                     parsed_lua_block:1;
} ngx_meta_lua_conf_t;


typedef struct {
    ngx_meta_lua_main_conf_handler_pt    init_handler;
    ngx_str_t                            init_src;
    lua_State                           *L;
} ngx_meta_lua_init_handler_t;


extern ngx_module_t ngx_meta_lua_module;


ngx_int_t ngx_meta_lua_run_delayed_init_handlers(ngx_meta_lua_conf_t *mcf,
    ngx_cycle_t *cycle, ngx_log_t *log);


#endif /* _NGX_META_LUA_H_INCLUDED_ */


/* vi:set ft=c ts=4 sw=4 et fdm=marker: */
