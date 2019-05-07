--[[
    处理玩家暗杠结果通知
]]
local Handler = {}
Handler.VERSION = "1.0"
local proto = require "scripts/proto/proto"

function Handler.onMsg(actionResultMsg, room)
    --print('llwant, ConcealedKong result')

    local targetChairID = actionResultMsg.targetChairID
    local player = room:getPlayerByChairID(targetChairID)
    local kongTileId = actionResultMsg.actionTile

    --从手牌移除4张
    for _ = 1, 4 do
        player:removeTileFromHand(kongTileId)
    end

    --暗杠需要构建一个新的meld
    local newMeld = {
        meldType = proto.mahjong.MeldType.enumMeldTypeConcealedKong,
        tile1 = kongTileId,
        contributor = player.chairID
    }
    player:addMeld(newMeld)

    --播放暗杠动画
    player:concealedKongResultAnimation()

    --手牌列表更新UI
    player:hand2UI()
end

return Handler
