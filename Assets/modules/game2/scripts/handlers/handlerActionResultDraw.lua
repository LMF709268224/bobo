--[[
    处理玩家抽牌结果通知，包含花牌（可能有多张，或没有）和一张非花牌
]]
local Handler = {}
Handler.VERSION = "1.0"
local proto = require "scripts/proto/proto"

function Handler.onMsg(actionResultMsg, room)
    --print('llwant, Draw result')

    local tilesFlower = actionResultMsg.newFlowers
    local targetChairID = actionResultMsg.targetChairID
    local player = room:getPlayerByChairID(targetChairID)
    local drawTile = actionResultMsg.actionTile

    --本次抽牌如果有抽到花牌，则把花牌保存到player的花牌列表
    --并显示出来
    if tilesFlower ~= nil and #tilesFlower > 0 then
        --player:addFlowerTiles(tilesFlower)
        --player.playerView:playDrawFlowerAnimation()
        --player:flower2UI()
        player:waitSecond(0.5)
        for _, flower in ipairs(tilesFlower) do
            local xf = {}
            player.playerView:showFlowerOnHandTail(flower)
            player.playerView:playDrawFlowerAnimation()
            player.playerView:hideFlowerOnHandTail()
            xf[1] = flower
            player:addFlowerTiles(xf)
            player:flower2UI()
        end
    end

    --增加新抽到的牌到手牌列表
    --显示的时候要摆在新抽牌位置
    --enumTid_MAX+1是一个特殊标志，表明服务器已经没牌可抽
    if drawTile ~= (1 + proto.mahjong.TileID.enumTid_MAX) then
        player:addHandTile(drawTile)
        player:sortHands(true) -- 新抽牌，必然有14张牌，因此最后一张牌不参与排序
        player:hand2UI()
    end

    room.tilesInWall = actionResultMsg.tilesInWall
    room:updateTilesInWallUI()

    room:hideDiscardedTips()
end

return Handler
