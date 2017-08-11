local arg = arg
local subsystem = arg[1]
local template_name = arg[2]
local type = type
local ipairs = ipairs

-- similar to ngx.print(), write tables recursively
local function io_print(f, buf)
    if type(buf) == 'table' then
        for _, b in ipairs(buf) do
            io_print(f, b)
        end

        return
    end

    if type(buf) ~= 'string' then
        error('unexpected type: ' .. type(buf))
    end

    f:write(buf)
end

local output_name = template_name
template_name = template_name:gsub('ngx_.-_lua', 'ngx_subsystem_lua')

local template = require('build.templates')
local compiled = template.process(template_name .. '.tt2',
                                  {
                                      subsystem = subsystem,
                                      req_type = subsystem == 'http'
                                          and 'ngx_http_request_t'
                                          or 'ngx_stream_lua_request_t',
                                  })

local f
if output_name == 'ngx_http_lua_api.h' or
   output_name == 'ngx_stream_lua_api.h' then
    f = assert(io.open('build/src/api/' .. output_name, 'w'))
else
    f = assert(io.open('build/src/' .. output_name, 'w'))
end

io_print(f, compiled)

f:close()
