
/*
 * Copyright (C) Xiaozhe Wang (chaoslawful)
 * Copyright (C) Yichun Zhang (agentzh)
 */


#ifndef _NGX_META_LUA_PCREFIX_H_INCLUDED_
#define _NGX_META_LUA_PCREFIX_H_INCLUDED_


#include "ngx_meta_lua_common.h"


#if (NGX_PCRE)
ngx_pool_t *ngx_meta_lua_pcre_malloc_init(ngx_pool_t *pool);
void ngx_meta_lua_pcre_malloc_done(ngx_pool_t *old_pool);
#endif


#endif /* _NGX_META_LUA_PCREFIX_H_INCLUDED_ */

/* vi:set ft=c ts=4 sw=4 et fdm=marker: */
