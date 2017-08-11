#include <ngx_config.h>
#include <ngx_core.h>
#include <ngx_stream.h>
#include "ngx_stream_lua_request.h"


ngx_stream_lua_cleanup_t *
ngx_stream_lua_cleanup_add(ngx_stream_lua_request_t *r, size_t size)
{
    ngx_stream_lua_cleanup_t  *cln;

    cln = ngx_palloc(r->pool, sizeof(ngx_stream_lua_cleanup_t));
    if (cln == NULL) {
        return NULL;
    }

    if (size) {
        cln->data = ngx_palloc(r->pool, size);
        if (cln->data == NULL) {
            return NULL;
        }

    } else {
        cln->data = NULL;
    }

    cln->handler = NULL;
    cln->next = r->cleanup;

    r->cleanup = cln;

    ngx_log_debug1(NGX_LOG_DEBUG_STREAM, r->connection->log, 0,
                   "http cleanup add: %p", cln);

    return cln;
}

ngx_stream_lua_request_t *
ngx_stream_lua_create_request(ngx_stream_session_t *s)
{
    ngx_pool_t               *pool;
    ngx_stream_lua_request_t *r;

    pool = ngx_create_pool(NGX_DEFAULT_POOL_SIZE, s->connection->log);
    if (pool == NULL) {
        return NULL;
    }

    r = ngx_pcalloc(pool, sizeof(ngx_stream_lua_request_t));
    if (r == NULL) {
        return NULL;
    }

    r->connection = s->connection;
    r->session = s;
    r->pool = pool;

    return r;
}

void
ngx_stream_lua_free_request(ngx_stream_lua_request_t *r)
{
    ngx_stream_lua_cleanup_t  *cln;
    ngx_pool_t                *pool;

    cln = r->cleanup;
    r->cleanup = NULL;

    while (cln) {
        if (cln->handler) {
            cln->handler(cln->data);
        }

        cln = cln->next;
    }

    pool = r->pool;
    r->pool = NULL;

    ngx_destroy_pool(pool);
}
