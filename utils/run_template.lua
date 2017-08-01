local arg = arg
local subsystem = arg[1]
local template_name = arg[2]

local output_name = template_name
template_name = template_name:gsub('ngx_.-_lua', 'ngx_subsystem_lua')

local template = require('build.templates')
local compiled = template.process(template_name .. '.tt2',
                                  { subsystem = subsystem })

local f
if output_name == 'ngx_http_lua_api.h' or
   output_name == 'ngx_stream_lua_api.h' then
    f = assert(io.open('build/src/api/' .. output_name, 'w'))
else
    f = assert(io.open('build/src/' .. output_name, 'w'))
end

f:write(table.concat(compiled, ''))
f:close()
