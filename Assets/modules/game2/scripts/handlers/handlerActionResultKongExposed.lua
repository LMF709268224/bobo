--[[
    处理玩家明杠结果通知
]]
local Handler = {}
Handler.VERSION = "1.0"

function Handler.onMsg(actionResultMsg, room)
    --print('llwant, ExposedKong result')
    local actionMeld = actionResultMsg.actionMeld
    local targetChairID = actionResultMsg.targetChairID
    local player = room:getPlayerByChairID(targetChairID)
    local kongTileId = actionMeld.tile1

    --清理吃牌界面
    room:cleanUI()
    --从手牌移除3张
    for _ = 1, 3 do
        player:removeTileFromHand(kongTileId)
    end

    --直接把消息meld保存到玩家的meld列表中
    player:addMeld(actionMeld)

    --如果newFlowers有内容，则需要刷新暗杠列表
    local newFlowers = actionResultMsg.newFlowers
    if newFlowers ~= nil and #newFlowers > 0 then
        player:refreshConcealedMelds(newFlowers)
    end

    --从贡献者（出牌者）的打出牌列表中移除最后一张牌
    local contributorPlayer = room:getPlayerByChairID(actionMeld.contributor)
    print("llwant, kongExposedTileID:" .. kongTileId .. ",contri:" .. actionMeld.contributor)
    --播放明杠动画
    player:exposedKongResultAnimation()

    --手牌列表更新UI
    player:hand2UI(true)

    --更新贡献者的打出牌列表到UI
    contributorPlayer:removeLatestDiscarded(kongTileId)
    contributorPlayer:discarded2UI()
    --隐藏箭头
    room.roomView:setArrowHide()
    room:hideDiscardedTips()
end

return Handler
