/*
 * Copyright (C) Yichun Zhang (agentzh)
 */


#ifndef _NGX_META_LUA_SHDICT_H_INCLUDED_
#define _NGX_META_LUA_SHDICT_H_INCLUDED_


#include "ngx_meta_lua_module.h"


typedef struct {
    u_char                       color;
    uint8_t                      value_type;
    u_short                      key_len;
    uint32_t                     value_len;
    uint64_t                     expires;
    ngx_queue_t                  queue;
    uint32_t                     user_flags;
    u_char                       data[1];
} ngx_meta_lua_shdict_node_t;


typedef struct {
    ngx_queue_t                  queue;
    uint32_t                     value_len;
    uint8_t                      value_type;
    u_char                       data[1];
} ngx_meta_lua_shdict_list_node_t;


typedef struct {
    ngx_rbtree_t                 rbtree;
    ngx_rbtree_node_t            sentinel;
    ngx_queue_t                  lru_queue;
} ngx_meta_lua_shdict_shctx_t;


typedef struct {
#if (NGX_DEBUG)
    ngx_int_t                    isold;
    ngx_int_t                    isinit;
#endif
    ngx_str_t                    name;
    ngx_meta_lua_shdict_shctx_t *sh;
    ngx_slab_pool_t             *shpool;
    ngx_meta_lua_conf_t         *mcf;
    ngx_log_t                   *log;
} ngx_meta_lua_shdict_ctx_t;


typedef struct {
    ngx_shm_zone_t               zone;
    ngx_cycle_t                 *cycle;
    ngx_meta_lua_conf_t         *mcf;
    ngx_log_t                   *log;
} ngx_meta_lua_shm_zone_ctx_t;


char *ngx_meta_lua_shdict_directive(ngx_conf_t *cf, ngx_command_t *cmd,
    void *conf);


#endif /* _NGX_META_LUA_SHDICT_H_INCLUDED_ */


/* vi:set ft=c ts=4 sw=4 et fdm=marker: */
