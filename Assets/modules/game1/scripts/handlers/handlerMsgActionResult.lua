--[[
    处理服务器下发的，玩家的操作结果通知消息，例如有玩家吃椪杠等
]]
local Handler={}
Handler.VERSION='1.0'
local dfPath = "GuanZhang/Script/"

require ( dfPath .. "Proto/game_pokerface_rf_pb")
local pokerfaceRf = game_pokerface_rf_pb
require ( dfPath .. "Proto/game_pokerface_pb")
local pokerface = game_pokerface_pb

local function initActoinHandlers()
    local handlers = {}

    local h = require ( dfPath .. 'dfMahjong/handlerActionResultDiscarded')
    handlers[pokerfaceRf.enumActionType_DISCARD] = h

    local h = require ( dfPath .. 'dfMahjong/handlerActionResultSkip')
    handlers[pokerfaceRf.enumActionType_SKIP] = h
    return handlers
end

Handler.actionhandlers = initActoinHandlers()

function Handler:onMsg(msg, room)
    --print(' Action result msg')
    --msg解析为MsgActionResultNotify
    local actionResultMsg = pokerface.MsgActionResultNotify()
    actionResultMsg:ParseFromString(msg)

    local action = actionResultMsg.action
    local handler = self.actionhandlers[action]

    if handler == nil then
        print(" no action handler for:"..action)
        return
    end

    handler:onMsg(actionResultMsg, room)

end

return Handler
