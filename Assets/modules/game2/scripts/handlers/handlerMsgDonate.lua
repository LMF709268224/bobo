--[[
    处理服务器下发的道具捐赠
]]
local Handler = {}
Handler.VERSION = "1.0"

local proto = require "scripts/proto/proto"
-- local mjproto = mjproto2

function Handler.onMsg(msgData, room)
    local msgDonate = proto.decodeMessage("mahjong.MsgDonate", msgData)
    room:showDonate(msgDonate)
end

return Handler
