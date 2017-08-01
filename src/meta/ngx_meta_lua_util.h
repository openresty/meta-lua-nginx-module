
/*
 * Copyright (C) Xiaozhe Wang (chaoslawful)
 * Copyright (C) Yichun Zhang (agentzh)
 */


#ifndef _NGX_META_LUA_UTIL_H_INCLUDED_
#define _NGX_META_LUA_UTIL_H_INCLUDED_


#include "ngx_meta_lua_common.h"


#ifndef NGX_UNESCAPE_URI_COMPONENT
#define NGX_UNESCAPE_URI_COMPONENT  0
#endif


/* char whose address we use as the key in Lua vm registry for
 * user code cache table */
extern char ngx_meta_lua_code_cache_key;


void ngx_meta_lua_unescape_uri(u_char **dst, u_char **src, size_t size,
    ngx_uint_t type);

uintptr_t ngx_meta_lua_escape_uri(u_char *dst, u_char *src,
    size_t size, ngx_uint_t type);

u_char *ngx_meta_lua_digest_hex(u_char *dest, const u_char *buf,
    int buf_len);

void ngx_meta_lua_set_multi_value_table(lua_State *L, int index);


#endif /* _NGX_META_LUA_UTIL_H_INCLUDED_ */

/* vi:set ft=c ts=4 sw=4 et fdm=marker: */
