package t::TestMeta;

use Test::Nginx::Socket::Lua -Base;
use Test::Nginx::Socket::Lua::Stream;
use Cwd qw(cwd);

our $pwd = cwd();

our $lua_package_path = '../lua-resty-core/lib/?.lua;../lua-resty-lrucache/lib/?.lua;;';

our $init_jit_settings = <<_EOC_;
    local verbose = false
    if verbose then
        local dump = require "jit.dump"
        dump.on("b", "$Test::Nginx::Util::ErrLogFile")
    else
        local v = require "jit.v"
        v.on("$Test::Nginx::Util::ErrLogFile")
    end
    --jit.off()
_EOC_

our @EXPORT = qw(
    $pwd
    $lua_package_path
    $init_jit_settings
);

add_block_preprocessor(sub {
    my $block = shift;

    if (!defined $block->config) {
        $block->set_value("config", "location /t { return 200; }");
    }

    if (!defined $block->request) {
        $block->set_value("request", "GET /t");
    }

    if (!defined $block->no_error_log && !defined $block->error_log
        && !defined $block->grep_error_log)
    {
        $block->set_value("no_error_log", "[error]");
    }
});

1;
