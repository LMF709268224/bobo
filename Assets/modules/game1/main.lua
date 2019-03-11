local logger = require 'lobby/lcore/logger'
logger.warn('i am game1')

-- 打印所有被C#引用着的LUA函数
local function print_func_ref_by_csharp()
    local registry = debug.getregistry()
    for k, v in pairs(registry) do
        if type(k) == 'number' and type(v) == 'function' and registry[v] == k then
            local info = debug.getinfo(v)
            print(string.format('%s:%d', info.short_src, info.linedefined))
        end
    end
end

-- 大写开头，由C#调用
function ShutdownCleanup()
	logger.warn('game1 main cleanup')
	print_func_ref_by_csharp()
end
