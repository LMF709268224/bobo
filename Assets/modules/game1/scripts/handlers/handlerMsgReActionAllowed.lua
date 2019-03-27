--[[
    处理服务器要求自己对别人打出牌后的动作的请求，例如过，吃椪杠，吃铳胡等
]]
local Handler={}
Handler.VERSION='1.0'
local dfPath = "GuanZhang/Script/"
local msgHelper = require ( dfPath .. "dfMahjong/msgHelper")
require ( dfPath .. "Proto/game_pokerface_rf_pb")
local pokerfaceRf = game_pokerface_rf_pb
require ( dfPath .. "Proto/game_pokerface_pb")
local pokerface = game_pokerface_pb

function Handler:onMsg(msg, room)
    --print(' ReAction allowed msg')


    local allowedReActionMsg = pokerface.MsgAllowPlayerReAction()
    allowedReActionMsg:ParseFromString(msg)

    local targetChairID = allowedReActionMsg.actionChairID
    local player = room:getPlayerByChairID(targetChairID)
    --隐藏打出的牌
    player.playerView:hideDiscarded()
    --TODO:开始倒计时
    room:startDiscardCountdown(player)

    --清除提示table
    player.tipCards = nil
    player.tipCardsIndex = 0

    if player:isMe() then
        print(" my allowed re-action")
        self:processMyAllowedReActions(allowedReActionMsg, player)
        --警告玩家，小心包牌
        local playerViews = room.roomView.playerViews
        if playerViews[2].player.cardCountOnHand < 4 then
            room.roomView.baopai:SetActive(true)
        end
    else
        print(" oh no, now support opponents re-action")
    end

    if allowedReActionMsg.timeoutInSeconds > 255 then
        player.discardR2H = true --保存必出红桃2的标志 (打出之后为false)
        --自动打
        player:autoDiscard()

    end
    --设置等待箭头
    room.roomView:setWaitingPlayer(player)
end

function Handler:processMyAllowedReActions(allowedReActionMsg, player)
    local actions = allowedReActionMsg.allowedActions

    player.allowedReActionMsg = allowedReActionMsg
    --删除Action的msg，以便操作按钮点击回调时辨识
    player.allowedActionMsg = nil

    local playerView = player.playerView

    local needShowOperationButtons = true
    playerView.discardHuiBtn:SetActive(true)
    playerView.tipBtn:SetActive(true)  --提示按钮
    playerView.skipHuiBtn:SetActive(true)
    print(" processMyAllowedReActions actions : "..tostring(actions))

    --如果可以过
    if msgHelper:actionsHasAction(actions, pokerfaceRf.enumActionType_SKIP) then
        print(" can skip")
        needShowOperationButtons = true
        playerView.skipHuiBtn:SetActive(false)
        playerView.skipBtn:SetActive(true)
    end

    --出牌
    if msgHelper:actionsHasAction(actions, pokerfaceRf.enumActionType_DISCARD) then
        print(" can discard")
        needShowOperationButtons = true
        playerView.discardHuiBtn:SetActive(false)
        playerView.discardBtn:SetActive(true)
    end
end

return Handler
