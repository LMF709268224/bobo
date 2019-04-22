--[[
    处理服务器下发的一手牌结束的消息
    一手牌结束后分数结算
]]
local Handler = {}

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

function Handler.onMsg(msgData, room)
    logger.debug("llwant game over msg")

    local msgGameOver = proto.decodeMessage("pokerface.MsgGameOver", msgData)

    --把结果保存到 room
    room.msgGameOver = msgGameOver
    --显示游戏最后结果()
    room:loadGameOverResultView()
end

return Handler
