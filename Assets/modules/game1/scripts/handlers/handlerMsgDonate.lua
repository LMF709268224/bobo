--[[
    处理服务器下发的道具捐赠
]]
local Handler = {}
Handler.VERSION = "1.0"

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

function Handler.onMsg(msgData, room)
    logger.debug("llwant Donate msg")

    local msgDonate = proto.decodeGameMessageData("pokerface.MsgDonate", msgData)
    --
    --logError("-------------------- msgDonate item :"..tostring(msgDonate.itemID))
    --logError("-------------------- msgDonate toChairID :"..tostring(msgDonate.toChairID))
    --logError("-------------------- msgDonate fromChairID :"..tostring(msgDonate.fromChairID))
    room:showDonate(msgDonate)
end

return Handler
