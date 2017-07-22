local arg = arg
local subsystem = arg[1]
local template_name = arg[2]

local output_name = template_name
template_name = template_name:gsub('ngx_.-_lua', 'ngx_subsystem_lua')

local template = require('build.templates')
local compiled = template.process(template_name .. '.tt2',
                                  { subsystem = subsystem })
local f = assert(io.open('build/src/' .. output_name, 'w'))

f:write(table.concat(compiled, ''))
f:close()
