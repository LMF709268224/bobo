--[[
    处理有玩家打过
]]
local Handler = {}

function Handler.onMsg(actionResultMsg, room)
    --这里只要播放  要不起
    local targetChairID = actionResultMsg.targetChairID
    local player = room:getPlayerByChairID(targetChairID)

    --隐藏打出的牌
    player.playerView:hideDiscarded()

    player.playerView:playSkipAnimation()
end

return Handler
