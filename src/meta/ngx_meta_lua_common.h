
/*
 * Copyright (C) Xiaozhe Wang (chaoslawful)
 * Copyright (C) Yichun Zhang (agentzh)
 */


#ifndef _NGX_META_LUA_COMMON_H_INCLUDED_
#define _NGX_META_LUA_COMMON_H_INCLUDED_


#include <nginx.h>
#include <ngx_core.h>
#include <ngx_md5.h>

#include <setjmp.h>
#include <stdint.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>


#if (NGX_PCRE)

#include <pcre.h>

#if (PCRE_MAJOR > 8) || (PCRE_MAJOR == 8 && PCRE_MINOR >= 21)
#   define LUA_HAVE_PCRE_JIT 1
#else
#   define LUA_HAVE_PCRE_JIT 0
#endif

#endif


#if !defined(nginx_version) || (nginx_version < 1006000)
#error at least nginx 1.6.0 is required but found an older version
#endif


#ifndef NGX_META_LUA_MAX_ARGS
#define NGX_META_LUA_MAX_ARGS 100
#endif


#if LUA_VERSION_NUM != 501
#   error unsupported Lua language version
#endif


#if (!defined OPENSSL_NO_OCSP && defined SSL_CTRL_SET_TLSEXT_STATUS_REQ_CB)
#   define NGX_META_LUA_USE_OCSP 1
#endif


#ifndef NGX_HAVE_SHA1
#   if (nginx_version >= 1011002)
#       define NGX_HAVE_SHA1  1
#   endif
#endif


#ifndef MD5_DIGEST_LENGTH
#define MD5_DIGEST_LENGTH 16
#endif


#ifdef NGX_LUA_USE_ASSERT
#   include <assert.h>
#   define ngx_meta_lua_assert(a)  assert(a)
#else
#   define ngx_meta_lua_assert(a)
#endif


/* Nginx HTTP Lua Inline tag prefix */

#define NGX_META_LUA_INLINE_TAG "nhli_"

#define NGX_META_LUA_INLINE_TAG_LEN \
    (sizeof(NGX_META_LUA_INLINE_TAG) - 1)

#define NGX_META_LUA_INLINE_KEY_LEN \
    (NGX_META_LUA_INLINE_TAG_LEN + 2 * MD5_DIGEST_LENGTH)

/* Nginx HTTP Lua File tag prefix */

#define NGX_META_LUA_FILE_TAG "nhlf_"

#define NGX_META_LUA_FILE_TAG_LEN \
    (sizeof(NGX_META_LUA_FILE_TAG) - 1)

#define NGX_META_LUA_FILE_KEY_LEN \
    (NGX_META_LUA_FILE_TAG_LEN + 2 * MD5_DIGEST_LENGTH)


#endif /* _NGX_META_LUA_COMMON_H_INCLUDED_ */

/* vi:set ft=c ts=4 sw=4 et fdm=marker: */
