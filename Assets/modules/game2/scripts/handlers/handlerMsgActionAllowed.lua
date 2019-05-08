--[[
    处理服务器要求自己动作的请求，例如出牌，暗杠，自摸胡牌，起手听牌等
]]
local Handler = {}
Handler.VERSION = "1.0"

local proto = require "scripts/proto/proto"

function Handler.onMsg(msg, room)
    --print('llwant, Action allowed msg')

    --TODO:开启倒计时
    --room:startDiscardCountdown(31)
    local allowedActionMsg = proto.decodeMessage("mahjong.MsgAllowPlayerAction", msg)
    -- allowedActionMsg:ParseFromString(msg)

    local targetChairID = allowedActionMsg.actionChairID
    local player = room:getPlayerByChairID(targetChairID)

    if player:isMe() then
        print("llwant, my allowed action")
        Handler.processMyAllowedActions(allowedActionMsg, player)
    else
        --TODO: 如果是别人，则更新它的头像等待圈，以及提醒定时器
        print("llwant, opponents allowed action")
    end

    --设置等待箭头
    room.roomView:setWaitingPlayer(player)

    if player.isRichi and player:isMe() then
        --听牌状态下，直接出牌，不等待
        player:autoDiscard()
    end
end

function Handler.processMyAllowedActions(allowedActionMsg, player)
    local actions = allowedActionMsg.allowedActions
    player.allowedActionMsg = allowedActionMsg
    --删除ReAction的msg，以便操作按钮点击回调时辨识
    player.allowedReActionMsg = nil

    --重置一下readyHandList
    player:updateReadyHandList(nil)

    local playerView = player.playerView

    local needShowOperationButtons = false
    player.waitSkip = false
    -- 过胡牌提示只有在胡和过同时存在才是true，任何情况都为false
    player.isGuoHuTips = false

    local at = proto.mahjong.ActionType
    --如果可以抓牌
    -- if proto.actionsHasAction(actions, at.enumActionType_AccumulateWin) then
    --     needShowOperationButtons = true
    --     playerView.finalDrawBtn.visible = true
    --     player.waitSkip = true
    -- end

    --如果可以起手听牌
    if proto.actionsHasAction(actions, at.enumActionType_FirstReadyHand) then
        print("llwant, can ready hand")
        needShowOperationButtons = true
        playerView.readyHandBtn.visible = true
        --这个标志用来判断可否出牌，当点击了动作按钮之后flagsAction会设置为true，这时候才可以出牌
        player.waitSkip = true
    end

    --如果可以自摸胡牌
    if proto.actionsHasAction(actions, at.enumActionType_SKIP) then
        print("llwant, can skip")
        needShowOperationButtons = true
        playerView.skipBtn.visible = true
    end

    --如果可以暗杠
    if proto.actionsHasAction(actions, at.enumActionType_KONG_Concealed) then
        print("llwant, can concealed kong")
        needShowOperationButtons = true
        playerView.kongBtn.visible = true
    end

    --如果可以加杠
    if proto.actionsHasAction(actions, at.enumActionType_KONG_Triplet2) then
        print("llwant, can triplet2 kong")
        needShowOperationButtons = true
        playerView.kongBtn.visible = true
    end

    --如果可以自摸胡牌
    if proto.actionsHasAction(actions, at.enumActionType_WIN_SelfDrawn) then
        print("llwant, can win self drawn")
        needShowOperationButtons = true

        playerView.winBtn.visible = true
    end

    -- 可胡牌时，需要点击2次过才可过牌。
    if proto.actionsHasAction(actions, at.enumActionType_WIN_SelfDrawn) then
        if proto.actionsHasAction(actions, at.enumActionType_SKIP) then
            -- 放弃胡牌，点击过时的提示开关
            player.isGuoHuTips = true
        end
    end

    --出牌
    if proto.actionsHasAction(actions, at.enumActionType_DISCARD) then
        print("llwant, can discard")
        --TODO: 设置打出后有牌可听的牌一个“听”标志
        --设置那些不能打的牌，一个黄色遮罩
        local discarAbleTilesMap = {}
        local discarAbleTiles = allowedActionMsg.tipsForAction
        for _, discardAbleTile in ipairs(discarAbleTiles) do
            discarAbleTilesMap[discardAbleTile.targetTile] = discardAbleTile
        end

        local handsClickCtrls = playerView.handsClickCtrls
        if player.isRichi then
            for i = 1, 13 do
                local handsClickCtrl = handsClickCtrls[i]
                handsClickCtrl.isDiscardable = false
                handsClickCtrl.isGray = true
                playerView:setGray(handsClickCtrl.h)
            end
            local handsClickCtrl14 = handsClickCtrls[14]
            handsClickCtrl14.isDiscardable = true

            if #discarAbleTiles[1].readyHandList < 1 then
                handsClickCtrl14.t.visible = false
            else
                handsClickCtrl14.t.visible = true
            end
        else
            --检查所有可以打出的牌，并设置其点击控制isDiscardable为true，以便玩家可以点击
            for i = 1, 14 do
                local handsClickCtrl = handsClickCtrls[i]
                local tileID = handsClickCtrl.tileID
                local discardAbleTile = discarAbleTilesMap[tileID]
                if tileID ~= nil then
                    if discardAbleTile ~= nil then
                        handsClickCtrl.isDiscardable = true
                        --playerView:resumeGray(handsClickCtrl.h)

                        --加入可听列表，空表示不可听
                        if #discardAbleTile.readyHandList < 1 then
                            handsClickCtrl.t.visible = false
                        else
                            handsClickCtrl.t.visible = true
                        end
                        handsClickCtrl.readyHandList = discardAbleTile.readyHandList
                    else
                        handsClickCtrl.isGray = true
                        playerView:setGray(handsClickCtrl.h)
                        handsClickCtrl.isDiscardable = false
                    end
                end
            end
        end
    end

    if needShowOperationButtons then
        playerView.operationButtonsRoot.visible = true
        --这个标志用来判断可否出牌，当点击了动作按钮之后flagsAction会设置为true，这时候才可以出牌
        player.waitSkip = true
    end
end

return Handler
