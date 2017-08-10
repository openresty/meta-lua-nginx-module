#ifndef _NGX_STREAM_LUA_REQUEST_H_INCLUDED_
#define _NGX_STREAM_LUA_REQUEST_H_INCLUDED_


typedef void (*ngx_stream_lua_cleanup_pt)(void *data);

typedef struct ngx_stream_lua_cleanup_s  ngx_stream_lua_cleanup_t;

struct ngx_stream_lua_cleanup_s {
    ngx_stream_lua_cleanup_pt               handler;
    void                                   *data;
    ngx_stream_lua_cleanup_t               *next;
};


typedef struct ngx_stream_lua_request_s     ngx_stream_lua_request_t;

struct ngx_stream_lua_request_s {
    ngx_connection_t                     *connection;
    ngx_stream_session_t                 *session;
    ngx_pool_t                           *pool;
    ngx_stream_lua_cleanup_t             *cleanup;
};


#endif /* _NGX_STREAM_LUA_REQUEST_H_INCLUDED_ */
