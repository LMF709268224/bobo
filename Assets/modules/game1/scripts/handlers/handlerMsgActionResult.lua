--[[
    处理服务器下发的，玩家的操作结果通知消息，例如有玩家吃椪杠等
]]
local Handler = {}
Handler.VERSION = "1.0"

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

local function initActoinHandlers()
    local handlers = {}

    local h = require("scripts/handlers/handlerActionResultDiscarded")
    handlers[proto.prunfast.ActionType.enumActionType_DISCARD] = h

    h = require("scripts/handlers/handlerActionResultSkip")
    handlers[proto.prunfast.ActionType.enumActionType_SKIP] = h
    return handlers
end

local actionhandlers = initActoinHandlers()

function Handler.onMsg(msgData, room)
    logger.debug(" Action result msg, length:", #msgData)
    --msg解析为MsgActionResultNotify
    local actionResultMsg = proto.decodeMessage("pokerface.MsgActionResultNotify", msgData)

    local action = actionResultMsg.action
    local handler = actionhandlers[action]

    if handler == nil then
        logger.debug(" no action handler for:" .. action)
        return
    end

    handler.onMsg(actionResultMsg, room)
end

return Handler
