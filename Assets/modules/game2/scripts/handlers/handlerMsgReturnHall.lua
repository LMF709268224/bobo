--[[
    处理服务器下发的发牌消息，发牌消息意味一手牌开始
]]
local Handler = {}

--local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

function Handler.onMsg(_, room)
    logger.debug(" return hall msg")
    --g_dataModule:SaveDataByKey("RoomInfo", room.roomInfo)
    room.isDestroy = true
end

return Handler
