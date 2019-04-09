--[[
    处理服务器要求自己对别人打出牌后的动作的请求，例如过，吃椪杠，吃铳胡等
]]
local Handler = {}
Handler.VERSION = "1.0"

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

function Handler.onMsg(msgData, room)
    logger.debug(" ReAction allowed msg")

    local allowedReActionMsg = proto.decodeMessage("pokerface.MsgAllowPlayerReAction", msgData)

    local targetChairID = allowedReActionMsg.actionChairID
    local player = room:getPlayerByChairID(targetChairID)
    --隐藏打出的牌
    player.playerView:hideDiscarded()
    --TODO:开始倒计时
    -- room:startDiscardCountdown(player)

    --清除提示table
    player.tipCards = nil
    player.tipCardsIndex = 0

    if player:isMe() then
        logger.debug(" my allowed re-action")
        Handler.processMyAllowedReActions(allowedReActionMsg, player)
        --警告玩家，小心包牌
        local playerViews = room.roomView.playerViews
        if playerViews[2].player.cardCountOnHand < 4 then
        -- room.roomView.baopai:SetActive(true)
        end
    else
        logger.debug(" oh no, now support opponents re-action")
    end

    if allowedReActionMsg.timeoutInSeconds > 255 then
        player.discardR2H = true --保存必出红桃2的标志 (打出之后为false)
        --自动打
        player:autoDiscard()
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

    --local needShowOperationButtons = true
    -- playerView.discardHuiBtn:SetActive(true)
    playerView.skipBtn.visible = false
    playerView.discardBtn.visible = false
    playerView.tipBtn.visible = true
    -- playerView.skipHuiBtn:SetActive(true)
    logger.debug(" processMyAllowedReActions actions : " .. tostring(actions))

    --如果可以过
    if proto.actionsHasAction(actions, proto.prunfast.ActionType.enumActionType_SKIP) then
        logger.debug(" can skip")
        --needShowOperationButtons = true
        -- playerView.skipHuiBtn:SetActive(false)
        playerView.skipBtn.visible = true
    end

    --出牌
    if proto.actionsHasAction(actions, proto.prunfast.ActionType.enumActionType_DISCARD) then
        logger.debug(" can discard")
        --needShowOperationButtons = true
        -- playerView.discardHuiBtn:SetActive(false)
        playerView.discardBtn.visible = true
    end
end

return Handler
