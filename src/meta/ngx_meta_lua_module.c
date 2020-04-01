/*
 * Copyright (C) Yichun Zhang (agentzh)
 */

#include <ngx_config.h>

#include "ngx_meta_lua_shdict.h"


static void *ngx_meta_lua_module_create_conf(ngx_cycle_t *cycle);
static char *ngx_meta_lua_block(ngx_conf_t *cf, ngx_command_t *cmd, void *conf);
static ngx_int_t ngx_meta_lua_run_init_handler(ngx_cycle_t *cycle,
    ngx_log_t *log, ngx_meta_lua_init_handler_t *inh);


static ngx_command_t ngx_meta_lua_cmds[] = {

    { ngx_string("lua"),
      NGX_MAIN_CONF|NGX_CONF_BLOCK|NGX_CONF_NOARGS,
      ngx_meta_lua_block,
      0,
      0,
      NULL },

    { ngx_string("lua_shared_dict"),
      NGX_META_LUA_CONF|NGX_CONF_TAKE2,
      ngx_meta_lua_shdict_directive,
      0,
      0,
      NULL },

    ngx_null_command
};


static ngx_core_module_t  ngx_meta_lua_module_ctx = {
    ngx_string("lua"),
    ngx_meta_lua_module_create_conf,
    NULL
};


ngx_module_t  ngx_meta_lua_module = {
    NGX_MODULE_V1,
    &ngx_meta_lua_module_ctx,              /* module context */
    ngx_meta_lua_cmds,                     /* module directives */
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


static void *
ngx_meta_lua_module_create_conf(ngx_cycle_t *cycle)
{
    ngx_meta_lua_conf_t         *mcf;

    mcf = ngx_pcalloc(cycle->pool, sizeof(ngx_meta_lua_conf_t));
    if (mcf == NULL) {
        return NULL;
    }

    mcf->shdict_zones = ngx_array_create(cycle->pool, 2,
                                         sizeof(ngx_shm_zone_t *));
    if (mcf->shdict_zones == NULL) {
        return NULL;
    }

    mcf->init_handlers = ngx_array_create(cycle->pool, 2,
                             sizeof(ngx_meta_lua_init_handler_t *));
    if (mcf->init_handlers == NULL) {
        return NULL;
    }

    return mcf;
}


static char *
ngx_meta_lua_block(ngx_conf_t *cf, ngx_command_t *cmd, void *conf)
{
    char                        *rv;
    ngx_conf_t                   pcf;
    ngx_meta_lua_conf_t         *mcf = *(ngx_meta_lua_conf_t **) conf;

    if (mcf->parsed_lua_block) {
        return "is duplicate";
    }

    /* parse the lua{} block */

    mcf->parsed_lua_block = 1;

    pcf = *cf;

    cf->ctx = mcf;
    cf->module_type = NGX_CORE_MODULE;
    cf->cmd_type = NGX_META_LUA_CONF;

    rv = ngx_conf_parse(cf, NULL);

    *cf = pcf;

    if (rv != NGX_CONF_OK) {
        return NGX_CONF_ERROR;
    }

    return NGX_CONF_OK;
}


ngx_int_t
ngx_meta_lua_post_init_handler(ngx_conf_t *cf,
    ngx_meta_lua_main_conf_handler_pt init_handler, ngx_str_t init_src,
    lua_State *L)
{
    ngx_meta_lua_conf_t              *mcf;
    ngx_meta_lua_init_handler_t     **inhp, *inh, iinh;

    if (init_handler == NULL) {
        return NGX_OK;
    }

    mcf = ngx_meta_lua_conf_get_main_conf(cf);

    if (!mcf->delay_init_handlers) {
        iinh.init_handler = init_handler;
        iinh.init_src = init_src;
        iinh.L = L;

        return ngx_meta_lua_run_init_handler(cf->cycle, cf->log, &iinh);
    }

    inh = ngx_palloc(cf->pool, sizeof(ngx_meta_lua_init_handler_t));
    if (inh == NULL) {
        return NGX_ERROR;
    }

    inh->init_handler = init_handler;
    inh->init_src = init_src;
    inh->L = L;

    inhp = ngx_array_push(mcf->init_handlers);
    if (inhp == NULL) {
        return NGX_ERROR;
    }

    *inhp = inh;

    return NGX_OK;
}


ngx_int_t
ngx_meta_lua_run_delayed_init_handlers(ngx_meta_lua_conf_t *mcf,
    ngx_cycle_t *cycle, ngx_log_t *log)
{
    ngx_uint_t                    i;
    ngx_meta_lua_init_handler_t **inhp;

    inhp = mcf->init_handlers->elts;

    /* respect order in which the modules were compiled */

    for (i = 0; i < mcf->init_handlers->nelts; i++) {
        ngx_log_debug1(NGX_LOG_DEBUG_CORE, log, 0,
                       "lua run delayed init_handler: %p", inhp[i]);

        if (ngx_meta_lua_run_init_handler(cycle, log, inhp[i]) != NGX_OK) {
            return NGX_ERROR;
        }
    }

    return NGX_OK;
}


static ngx_int_t
ngx_meta_lua_run_init_handler(ngx_cycle_t *cycle, ngx_log_t *log,
    ngx_meta_lua_init_handler_t *inh)
{
    volatile ngx_cycle_t         *saved_cycle;
    ngx_int_t                     rc;

    saved_cycle = ngx_cycle;
    ngx_cycle = cycle;

    rc = inh->init_handler(log, inh->init_src, inh->L);

    ngx_cycle = saved_cycle;

    if (rc != NGX_OK) {
        return NGX_ERROR;
    }

    return NGX_OK;
}


/* vi:set ft=c ts=4 sw=4 et fdm=marker: */
