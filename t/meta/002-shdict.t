# vim:set ft= ts=4 sw=4 et fdm=marker:
use lib '.';
use t::TestMeta;

plan tests => repeat_each() * (blocks() * 3);

$ENV{TEST_NGINX_LUA_PACKAGE_PATH} = "$t::TestMeta::lua_package_path";

no_long_string();
run_tests();

__DATA__

=== TEST 1: http{} - sanity
--- http_config
    lua_package_path "$TEST_NGINX_LUA_PACKAGE_PATH";
    lua_shared_dict dict 1m;
--- config
    location = /t {
        content_by_lua_block {
            ngx.shared.dict:set("foo", 42)
            ngx.say(ngx.shared.dict:get("foo"))
        }
    }
--- response_body
42



=== TEST 2: stream{} - sanity
--- stream_config
    lua_package_path "$TEST_NGINX_LUA_PACKAGE_PATH";
    lua_shared_dict dict 1m;
--- stream_server_config
    content_by_lua_block {
        ngx.shared.dict:set("foo", 42)
        ngx.say(ngx.shared.dict:get("foo"))
    }
--- response_body
42



=== TEST 3: http{} and stream{} - shdicts are isolated
--- stream_config
    lua_package_path "$TEST_NGINX_LUA_PACKAGE_PATH";
    lua_shared_dict stream_dict 1m;
--- stream_server_config
    content_by_lua_block {
        ngx.shared.stream_dict:set("foo", 42)
        ngx.say("stream_dict: ", ngx.shared.stream_dict:get("foo"))
        ngx.say("http_dict: ", tostring(ngx.shared.http_dict))
    }
--- http_config
    lua_package_path "$TEST_NGINX_LUA_PACKAGE_PATH";
    lua_shared_dict http_dict 1m;

    log_by_lua_block {
        ngx.log(ngx.NOTICE, "in http stream_dict: ",
                tostring(ngx.shared.stream_dict))
    }
--- response_body
stream_dict: 42
http_dict: nil
--- error_log
in http stream_dict: nil



=== TEST 4: lua{} - shdict is shared by all subsystems
--- main_config
    lua {
        lua_shared_dict dict 1m;
    }
--- stream_config
    lua_package_path "$TEST_NGINX_LUA_PACKAGE_PATH";
--- stream_server_config
    content_by_lua_block {
        ngx.say("from stream{}: ", ngx.shared.dict:get("key"))
        ngx.shared.dict:set("key", "set from stream{}")
    }
--- http_config
    lua_package_path "$TEST_NGINX_LUA_PACKAGE_PATH";
    access_by_lua_block {
        ngx.shared.dict:set("key", "set from http{}")
    }

    log_by_lua_block {
        ngx.log(ngx.NOTICE, "from http{}: ", ngx.shared.dict:get("key"))
    }
--- response_body
from stream{}: set from http{}
--- error_log
from http{}: set from stream{}



=== TEST 5: lua{} and http{} - same shdict name is invalid
--- main_config
    lua {
        lua_shared_dict dict 1m;
    }
--- http_config
    lua_shared_dict dict 1m;
    lua_package_path "$TEST_NGINX_LUA_PACKAGE_PATH";
--- ignore_response_body
--- must_die
--- error_log
the shared memory zone "dict" is already declared
--- no_error_log
[error]



=== TEST 6: lua{} and stream{} - same shdict name is invalid
--- main_config
    lua {
        lua_shared_dict dict 1m;
    }
--- stream_config
    lua_shared_dict dict 1m;
    lua_package_path "$TEST_NGINX_LUA_PACKAGE_PATH";
--- ignore_response_body
--- must_die
--- error_log
the shared memory zone "dict" is already declared
--- no_error_log
[error]



=== TEST 7: sanity check on ngx.shared size for each Lua VM
--- main_config
    lua {
        lua_shared_dict d1 1m;
        lua_shared_dict d2 1m;
    }
--- stream_config
    lua_shared_dict sd1 1m;
    lua_shared_dict sd2 1m;
    lua_package_path "$TEST_NGINX_LUA_PACKAGE_PATH";
--- stream_server_config
    content_by_lua_block {
        local n = 0
        for k in pairs(ngx.shared) do
            n = n + 1
        end
        ngx.say("stream ngx.shared nkeys: ", n)
    }
--- http_config
    lua_shared_dict hd1 1m;
    lua_package_path "$TEST_NGINX_LUA_PACKAGE_PATH";

    log_by_lua_block {
        local n = 0
        for k in pairs(ngx.shared) do
            n = n + 1
        end
        ngx.log(ngx.NOTICE, "http ngx.shared nkeys: ", n)
    }
--- response_body
stream ngx.shared nkeys: 4
--- error_log
http ngx.shared nkeys: 3
