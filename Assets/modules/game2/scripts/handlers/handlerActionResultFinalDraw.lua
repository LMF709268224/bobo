--[[
    处理玩家起手抓牌结果通知
]]
local Handler = {}
Handler.VERSION = "1.0"

function Handler.onMsg(actionResultMsg, room)
    local targetChairID = actionResultMsg.targetChairID
    local player = room:getPlayerByChairID(targetChairID)
    --播放抓拍动画
    player:playZhuaPaiAnimation()
end

return Handler
