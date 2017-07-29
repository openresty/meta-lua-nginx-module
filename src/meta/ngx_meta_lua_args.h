
/*
 * Copyright (C) Yichun Zhang (agentzh)
 */


#ifndef _NGX_META_LUA_ARGS_H_INCLUDED_
#define _NGX_META_LUA_ARGS_H_INCLUDED_


#include "ngx_meta_lua_common.h"


int ngx_meta_lua_parse_args(lua_State *L, u_char *buf, u_char *last, int max);


#endif /* _NGX_META_LUA_ARGS_H_INCLUDED_ */

/* vi:set ft=c ts=4 sw=4 et fdm=marker: */
