--[[
    处理服务器下发要求客户端显示一个tips的消息
]]
local Handler = {}

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

function Handler.onMsg(msgData, room)
    logger.debug(" update user game props cfg")

    local msgUpdatePropCfg = proto.decodeMessage("pokerface.MsgUpdatePropCfg", msgData)
    room:updatePropCfg(msgUpdatePropCfg)
end

return Handler
