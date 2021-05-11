
/*
 * Copyright (C) Yichun Zhang (agentzh)
 */


#ifndef _NGX_META_LUA_API_H_INCLUDED_
#define _NGX_META_LUA_API_H_INCLUDED_


#include <nginx.h>
#include <ngx_core.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>


#define ngx_meta_lua_version 00001


typedef ngx_int_t (*ngx_meta_lua_main_conf_handler_pt)(ngx_log_t *log,
    ngx_str_t init_src, lua_State *L);


ngx_int_t ngx_meta_lua_post_init_handler(ngx_conf_t *cf,
    ngx_meta_lua_main_conf_handler_pt init_handler, ngx_str_t init_src,
    lua_State *L);
char *ngx_meta_lua_shdict_directive_helper(ngx_conf_t *cf, void *tag);
void ngx_meta_lua_inject_shdict_api(lua_State *L, ngx_cycle_t *cycle,
    void *tag);


#endif /* _NGX_META_LUA_API_H_INCLUDED_ */


/* vi:set ft=c ts=4 sw=4 et fdm=marker: */
