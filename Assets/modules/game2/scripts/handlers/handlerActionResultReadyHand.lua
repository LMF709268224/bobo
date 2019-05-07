--[[
    处理玩家起手听牌结果通知
]]
local Handler={}
Handler.VERSION='1.0'

function Handler.onMsg(actionResultMsg, room)
    --print('llwant, Richi result')
    local targetChairID = actionResultMsg.targetChairID
    local player = room:getPlayerByChairID(targetChairID)

    player.isRichi = true

    --特效播放
    player:readyHandEffect()

    --头像上显示听牌标志
    player:richiIconShow(true)

end

return Handler
