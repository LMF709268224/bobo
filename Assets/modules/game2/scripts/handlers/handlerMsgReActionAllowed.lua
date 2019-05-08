--[[
    处理服务器要求自己对别人打出牌后的动作的请求，例如过，吃椪杠，吃铳胡等
]]
local Handler = {}
Handler.VERSION = "1.0"

local proto = require "scripts/proto/proto"

function Handler.onMsg(msg, room)
    --print('llwant, ReAction allowed msg')

    local allowedReActionMsg = proto.decodeMessage("mahjong.MsgAllowPlayerReAction", msg)

    -- allowedReActionMsg:ParseFromString(msg)

    local targetChairID = allowedReActionMsg.actionChairID
    local player = room:getPlayerByChairID(targetChairID)

    if player:isMe() then
        print("llwant, my allowed re-action")
        Handler.processMyAllowedReActions(allowedReActionMsg, player)
    else
        print("llwant, oh no, now support opponents re-action")
    end

    --设置等待箭头
    room.roomView:setWaitingPlayer(player)
end

function Handler.processMyAllowedReActions(allowedReActionMsg, player)
    local actions = allowedReActionMsg.allowedActions

    player.allowedReActionMsg = allowedReActionMsg
    --删除Action的msg，以便操作按钮点击回调时辨识
    player.allowedActionMsg = nil

    local playerView = player.playerView

    local needShowOperationButtons = false

    -- 过胡牌提示只有在胡和过同时存在才是true，任何情况都为false
    player.isGuoHuTips = false

    --如果可以吃
    local mjproto = proto.mahjong.ActionType
    if proto.actionsHasAction(actions, mjproto.enumActionType_CHOW) then
        print("llwant, can chow")
        needShowOperationButtons = true
        playerView.chowBtn.visible = true
    end

    --如果可以碰
    if proto.actionsHasAction(actions, mjproto.enumActionType_PONG) then
        print("llwant, can pong")
        needShowOperationButtons = true

        playerView.pongBtn.visible = true
    end

    --如果可以明杠
    if proto.actionsHasAction(actions, mjproto.enumActionType_KONG_Exposed) then
        print("llwant, can concealed kong")
        needShowOperationButtons = true

        playerView.kongBtn.visible = true
    end

    --如果可以吃铳胡牌
    if proto.actionsHasAction(actions, mjproto.enumActionType_WIN_Chuck) then
        print("llwant, can win chuck")
        needShowOperationButtons = true

        playerView.winBtn.visible = true
    end

    --如果可以过
    if proto.actionsHasAction(actions, mjproto.enumActionType_SKIP) then
        print("llwant, can skip")
        needShowOperationButtons = true
        playerView.skipBtn.visible = true
    end

    -- 可胡牌时，需要点击2次过才可过牌。
    if proto.actionsHasAction(actions, mjproto.enumActionType_WIN_Chuck) then
        if proto.actionsHasAction(actions, mjproto.enumActionType_SKIP) then
            -- 放弃胡牌，点击过时的提示开关
            player.isGuoHuTips = true
        end
    end

    if needShowOperationButtons then
        playerView.operationButtonsRoot.visible = true
    end
end

return Handler
