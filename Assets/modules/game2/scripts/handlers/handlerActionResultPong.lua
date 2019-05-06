--[[
    处理玩家碰牌结果通知
]]
local Handler = {}
Handler.VERSION = "1.0"

function Handler.onMsg(actionResultMsg, room)
    --print('llwant, Pong result')
    local actionMeld = actionResultMsg.actionMeld
    local targetChairID = actionResultMsg.targetChairID
    local player = room:getPlayerByChairID(targetChairID)
    local pongTileId = actionMeld.tile1

    --清理吃牌界面
    room:cleanUI()
    --从手牌移除2张
    for _ = 1, 2 do
        player:removeTileFromHand(pongTileId)
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
    print("llwant, kongExposedTileID:" .. pongTileId .. ",contri:" .. actionMeld.contributor)

    --播放碰牌动画
    player:pongResultAnimation()

    --手牌列表更新UI
    player:hand2UI(true)

    --更新贡献者的打出牌列表到UI
    contributorPlayer:removeLatestDiscarded(pongTileId)
    contributorPlayer:discarded2UI()
    --隐藏箭头
    room.roomView:setArrowHide()
    room:hideDiscardedTips()
end

return Handler
