--[[
    处理服务器要求自己动作的请求，例如出牌，暗杠，自摸胡牌，起手听牌等
]]
local Handler = {}
Handler.VERSION = "1.0"

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

function Handler.onMsg(msg, room)
    --logger.debug(' Action allowed msg')

    local allowedActionMsg = proto.decodeMessage("pokerface.MsgAllowPlayerAction", msg)
    local targetChairID = allowedActionMsg.actionChairID
    local player = room:getPlayerByChairID(targetChairID)

    --隐藏打出的牌
    player.playerView:hideDiscarded()
    --TODO:开启倒计时
    room:startDiscardCountdown(player)

    if allowedActionMsg.timeoutInSeconds > 255 then
        player.haveR3H = true --保存有过红桃3的标志 (打出之后为false)
    end

    if player:isMe() then
        logger.debug(" my allowed action")
        Handler.processMyAllowedActions(allowedActionMsg, player)

        --警告玩家，小心包牌
        local playerViews = room.roomView.playerViews
        if playerViews[2].player.cardCountOnHand < 4 then
            room.roomView.baopai:SetActive(true)
        end
    else
        --TODO: 如果是别人，则更新它的头像等待圈，以及提醒定时器
        logger.debug(" opponents allowed action")
    end
    --设置等待箭头
    room.roomView:setWaitingPlayer(player)
end

function Handler.processMyAllowedActions(allowedActionMsg, player)
    local actions = allowedActionMsg.allowedActions
    player.allowedActionMsg = allowedActionMsg
    --删除ReAction的msg，以便操作按钮点击回调时辨识
    player.allowedReActionMsg = nil

    local playerView = player.playerView

    local needShowOperationButtons = true
    player.waitSkip = false
    playerView.skipHuiBtn:SetActive(true)
    --playerView.tipHuiBtn:SetActive(true)

    --清除提示table
    player.tipCards = nil
    player.tipCardsIndex = 0

    logger.debug(" processMyAllowedActions actions : " .. tostring(actions))
    --如果可以过
    if proto.actionsHasAction(actions, proto.prunfast.ActionType.enumActionType_SKIP) then
        logger.debug(" can skip")
        needShowOperationButtons = true
        playerView.skipHuiBtn:SetActive(false)
        playerView.skipBtn:SetActive(true)
    end
    --出牌
    if proto.actionsHasAction(actions, proto.prunfast.ActionType.enumActionType_DISCARD) then
        logger.debug(" can discard")
        needShowOperationButtons = true
        playerView.discardBtn:SetActive(true)
        playerView.tipBtn:SetActive(true)
    end

    if needShowOperationButtons then
        --playerView.skipBtn:SetActive(true)
        --这个标志用来判断可否出牌，当点击了动作按钮之后flagsAction会设置为true，这时候才可以出牌
        player.waitSkip = true
    end
end

return Handler
