--[[
    处理玩家抽牌结果通知，包含花牌（可能有多张，或没有）和一张非花牌
]]
local Handler = {}

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

function Handler.onMsg(actionResultMsg, room)
    logger.debug(" Draw result")
    local targetChairID = actionResultMsg.targetChairID
    local player = room:getPlayerByChairID(targetChairID)
    local drawTile = actionResultMsg.actionTile
    --增加新抽到的牌到手牌列表
    --显示的时候要摆在新抽牌位置
    --enumTid_MAX+1是一个特殊标志，表明服务器已经没牌可抽
    if drawTile ~= (1 + proto.pokerface.CardID.CARDMAX) then
        player:addHandTile(drawTile)
        player:sortHands(true) -- 新抽牌，必然有14张牌，因此最后一张牌不参与排序
        player:hand2UI()
    end
end

return Handler
