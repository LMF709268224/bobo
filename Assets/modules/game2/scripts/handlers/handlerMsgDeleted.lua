--[[
    处理服务器下发的通知各个玩家，房间已经被解散，或者被删除
]]
local Handler = {}
Handler.VERSION = "1.0"
local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

function Handler.onMsg(msgData, room)
    --print('llwant, room deleted msg')
    room.isDestroy = true

    local msgDelete = proto.decodeMessage("mahjong.MsgRoomDelete", msgData)
    -- msgDelete:ParseFromString(msgData)

    local mjproto2 = proto.mahjong.RoomDeleteReason

    local msg = "房间已解散"
    if msgDelete.reason == mjproto2.IdleTimeout then
        msg = "房间空置时间过长，被解散"
    elseif msgDelete.reason == mjproto2.DisbandByOwnerFromRMS then
        msg = "房间被房主解散"
    elseif msgDelete.reason == mjproto2.DisbandByApplication then
        -- return false --房间被申请解散时，这里就不处理了 (直接返回)
        msg = "房间被申请解散"
    elseif msgDelete.reason == mjproto2.DisbandBySystem then
        msg = "房间被系统解散"
    elseif msgDelete.reason == mjproto2.DisbandMaxHand then
        -- return false --为了在大结算的时候直接返回大厅，这里就不处理了 (直接返回)
        msg = "房间已达到最大局数，被解散"
    elseif msgDelete.reason == mjproto2.DisbandInLoseProtected then
        msg = "房间已有足够人进园子，牌局被解散"
    end

    logger.debug("room deleted reason:", msg)
    room.host.mq:pushQuit()
end

return Handler
