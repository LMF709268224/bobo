--[[
    处理玩家加杠结果通知
]]
local Handler = {}
Handler.VERSION = "1.0"
local proto = require "scripts/proto/proto"

function Handler.onMsg(actionResultMsg, room)
    --print('llwant, Triplet2Kong result')

    local targetChairID = actionResultMsg.targetChairID
    local player = room:getPlayerByChairID(targetChairID)
    local kongTileId = actionResultMsg.actionTile

    --从手牌移除1张
    player:removeTileFromHand(kongTileId)

    --修改之前的碰牌牌组为加杠
    local meld = player:getMeld(kongTileId, proto.mahjong.MeldType.enumMeldTypeTriplet)
    meld.meldType = proto.mahjong.MeldType.enumMeldTypeTriplet2Kong

    --播放加杠动画
    player:triplet2KongResultAnimation()

    --手牌列表更新UI
    player:hand2UI()
end

return Handler
