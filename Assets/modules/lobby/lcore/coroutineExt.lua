--[[
    CoroutineExt 扩展工具
]]
--luacheck: no self
local CoroutineExt = {}
local logger = require "lobby/lcore/logger"

function CoroutineExt.waitSecond(component, someSecond)
        local waitCo = coroutine.running()
        component:DelayRun(
            someSecond,
            function()
                local flag, msg = coroutine.resume(waitCo)
                if not flag then
                    logger.error(msg)
                    return
                end
            end
        )
        coroutine.yield()
end

return CoroutineExt