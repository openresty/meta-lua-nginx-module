# vim:set ft= ts=4 sw=4 et fdm=marker:
use lib '.';
use t::TestMeta;

plan tests => repeat_each() * (blocks() * 2);

add_block_preprocessor(sub {
    my $block = shift;

    my $http_init_by_lua_block = $block->http_init_by_lua_block || '';
    my $stream_init_by_lua_block = $block->stream_init_by_lua_block || '';
    my $http_config = $block->http_config || '';
    my $stream_config = $block->stream_config || '';

    $http_config .= <<_EOC_;
    lua_package_path '$t::TestMeta::lua_package_path';
    init_by_lua_block { $http_init_by_lua_block }
_EOC_

    $stream_config .= <<_EOC_;
    lua_package_path '$t::TestMeta::lua_package_path';
    init_by_lua_block { $stream_init_by_lua_block }
_EOC_

    $block->set_value("http_config", $http_config);
    $block->set_value("stream_config", $stream_config);
    $block->set_value("stream_server_config", <<_EOC_);
    content_by_lua_block { ngx.say("ok") }
_EOC_
});

no_long_string();
run_tests();

__DATA__

=== TEST 1: lua{} block - sanity
--- main_config
    lua {}
--- no_error_log
[error]



=== TEST 2: lua{} block - duplicated block
--- main_config
    lua {}
    lua {}
--- must_die
--- error_log
"lua" directive is duplicate



=== TEST 3: lua{} block - invalid context
--- http_config
    lua {}
--- must_die
--- error_log
"lua" directive is not allowed here



=== TEST 4: lua{} block - execute http{} init_by_lua
--- main_config
    lua {}
--- http_init_by_lua_block
print("hello from http{} init_by_lua_block")
--- error_log
hello from http{} init_by_lua_block



=== TEST 5: lua{} block - execute stream{} init_by_lua
--- main_config
    lua {}
--- stream_init_by_lua_block
print("hello from stream{} init_by_lua_block")
--- error_log
hello from stream{} init_by_lua_block



=== TEST 6: lua{} block - execute stream{} + http{} init_by_lua
--- main_config
    lua {}
--- http_init_by_lua_block
print("hello from http{} init_by_lua_block")
--- stream_init_by_lua_block
print("hello from stream{} init_by_lua_block")
--- grep_error_log eval: qr/hello from (?:http|stream)\{\} init_by_lua_block/
--- grep_error_log_out
hello from stream{} init_by_lua_block
hello from http{} init_by_lua_block



=== TEST 7: lua{} block - execute stream{} + http{} delayed init_by_lua
--- main_config
    lua {
        lua_shared_dict shm 64k;
    }
--- http_init_by_lua_block
print("hello from http{} init_by_lua_block")
--- stream_init_by_lua_block
print("hello from stream{} init_by_lua_block")
--- grep_error_log eval: qr/(?:hello from (?:http|stream)\{\} init_by_lua_block|lua run delayed init_handler: [0-9A-F]+)/
--- grep_error_log_out eval
qr/lua run delayed init_handler: [0-9A-F]+
hello from stream\{\} init_by_lua_block
lua run delayed init_handler: [0-9A-F]+
hello from http\{\} init_by_lua_block/
