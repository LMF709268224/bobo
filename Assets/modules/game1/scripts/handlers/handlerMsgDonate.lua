--[[
    处理服务器下发的道具捐赠
]]
local Handler = {}

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

function Handler.onMsg(msgData, room)
    logger.debug("llwant Donate msg")

    local msgDonate = proto.decodeMessage("pokerface.MsgDonate", msgData)
    room:showDonate(msgDonate)
end

return Handler
