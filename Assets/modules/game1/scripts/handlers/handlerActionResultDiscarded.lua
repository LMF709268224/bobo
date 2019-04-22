--[[
    处理有玩家打出一张牌结果通知
]]
local Handler = {}

local logger = require "lobby/lcore/logger"

function Handler.onMsg(actionResultMsg, room)
    logger.debug(" Discarded result")

    local targetChairID = actionResultMsg.targetChairID
    local player = room:getPlayerByChairID(targetChairID)
    local discardTileIds = actionResultMsg.actionHand.cards

    for _, v in ipairs(discardTileIds) do
        --从手牌移除
        player:removeTileFromHand(v)
        --加到打出牌列表
        player:addDicardedTile(v)
    end

    --排一下序,sortHands会根据tilesHand表格是否为nil，做出排序选择
    player:sortHands()

    --更新UI
    player:hand2UI()
    player:discarded2UI(discardTileIds)
    player:showCardHandType(actionResultMsg.actionHand.cardHandType, discardTileIds[1])
end

return Handler
