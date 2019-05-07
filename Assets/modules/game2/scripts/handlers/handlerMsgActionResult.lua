--[[
    处理服务器下发的，玩家的操作结果通知消息，例如有玩家吃椪杠等
]]
local Handler = {}
Handler.VERSION = "1.0"

local proto = require "scripts/proto/proto"
-- local logger = require "lobby/lcore/logger"

local function initActoinHandlers()
    local handlers = {}

    local h = require("scripts/handlers/handlerActionResultChow")
    handlers[proto.mahjong.ActionType.enumActionType_CHOW] = h

    h = require("scripts/handlers/handlerActionResultDraw")
    handlers[proto.mahjong.ActionType.enumActionType_DRAW] = h

    h = require("scripts/handlers/handlerActionResultKongConcealed")
    handlers[proto.mahjong.ActionType.enumActionType_KONG_Concealed] = h

    h = require("scripts/handlers/handlerActionResultKongExposed")
    handlers[proto.mahjong.ActionType.enumActionType_KONG_Exposed] = h

    h = require("scripts/handlers/handlerActionResultPong")
    handlers[proto.mahjong.ActionType.enumActionType_PONG] = h

    h = require("scripts/handlers/handlerActionResultReadyHand")
    handlers[proto.mahjong.ActionType.enumActionType_FirstReadyHand] = h

    h = require("scripts/handlers/handlerActionResultTriplet2Kong")
    handlers[proto.mahjong.ActionType.enumActionType_KONG_Triplet2] = h

    h = require("scripts/handlers/handlerActionResultDiscarded")
    handlers[proto.mahjong.ActionType.enumActionType_DISCARD] = h

    -- h = require("scripts/handlers/handlerActionResultFinalDraw")
    -- handlers[proto.mahjong.ActionType.enumActionType_AccumulateWin] = h

    return handlers
end

local actionhandlers = initActoinHandlers()

function Handler.onMsg(msg, room)
    --print('llwant, Action result msg')
    --msg解析为MsgActionResultNotify
    local actionResultMsg = proto.decodeMessage("mahjong.MsgActionResultNotify", msg)
    -- actionResultMsg:ParseFromString(msg)

    local action = actionResultMsg.action

    local handler = actionhandlers[action]

    if handler == nil then
        print("llwant, no action handler for:" .. action)
        return
    end
    handler.onMsg(actionResultMsg, room)

    --起手听牌比较特殊，因为服务器是每收到一个起手听，立即广播给其他人
    --因此如果本玩家还处于选择起手听状态，那么不应该把操作面板关闭
    --其他情况，既然本人或者其他用户做出了选择，那么应该确保操作面板是关闭的
    if action ~= proto.mahjong.ActionType.enumActionType_FirstReadyHand then
        local myPlayer = room:me()
        myPlayer.playerView:hideOperationButtons()
    end
end

return Handler
