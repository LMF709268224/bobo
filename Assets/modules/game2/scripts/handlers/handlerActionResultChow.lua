--[[
    处理吃牌结果通知
]]
local Handler = {}
Handler.VERSION = "1.0"

function Handler.onMsg(actionResultMsg, room)
    --print('llwant, Chow result')

    local actionMeld = actionResultMsg.actionMeld
    local targetChairID = actionResultMsg.targetChairID
    local player = room:getPlayerByChairID(targetChairID)
    local chowTileId = actionResultMsg.actionTile

    --从手牌移除两张
    for i = 0, 2 do
        local tileId = actionMeld.tile1 + i
        if tileId ~= chowTileId then
            player:removeTileFromHand(tileId)
        end
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
    print("llwant, chowTileID:" .. chowTileId .. ",contri:" .. actionMeld.contributor)

    --播放吃牌动画
    player:chowResultAnimation()

    --手牌列表更新UI
    player:hand2UI(true)

    contributorPlayer:removeLatestDiscarded(chowTileId)
    --更新贡献者的打出牌列表到UI
    contributorPlayer:discarded2UI()

    --隐藏箭头
    room.roomView:setArrowHide()
    room:hideDiscardedTips()
end

return Handler
