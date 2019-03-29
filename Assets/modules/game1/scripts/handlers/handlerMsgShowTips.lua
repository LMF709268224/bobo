--[[
    处理服务器下发要求客户端显示一个tips的消息
]]
local Handler = {}
Handler.VERSION = "1.0"

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

function Handler.onMsg(msgData, room)
    logger.debug(" room show tips msg, room id", room.id)

    local msgRoomShowTips = proto.decodeGameMessageData("pokerface.MsgRoomShowTips", msgData)

    if msgRoomShowTips.tipCode == proto.pokerface.TipCode.TCNone then
        logger.debug("<<<" .. msgRoomShowTips.tips .. ">>>")
    --dfCompatibleAPI:showTip("" .. msgRoomShowTips.tips)
    --elseif msgRoomShowTips.tipCode == pkproto2.TCWaitOpponentsAction then
    --ViewManager.ShowTip("正在等待其他玩家操作")
    --elseif msgRoomShowTips.tipCode == pkproto2.TCDonateFailedNoEnoughDiamond then
    --    dfCompatibleAPI:showTip("打赏失败，钻石不足")
    end
end

return Handler
