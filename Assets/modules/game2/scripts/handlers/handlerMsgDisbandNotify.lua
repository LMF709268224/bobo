--[[
    处理服务器下发的解散房间请求回复，以及房间解散状态通知
]]
local Handler = {}
Handler.VERSION = "1.0"

local proto = require "scripts/proto/proto"
-- local logger = require "lobby/lcore/logger"

function Handler.onMsg(msgData, room)
    --print('llwant, handle disband notify')

    --先清除room的msgDisbandNotify
    room.disbandLocked = false
    local msgDisbandNotify = proto.decodeMessage("mahjong.MsgDisbandNotify", msgData)
    local mjproto2 = proto.mahjong.DisbandState
    -- msgDisbandNotify:ParseFromString(msgData)

    if msgDisbandNotify.disbandState == mjproto2.Waiting then
        --保存到room到，以便重复点击申请解散按钮进而显示
        room.disbandLocked = true
        room:updateDisbandVoteView(msgDisbandNotify)
    -- elseif
    --     msgDisbandNotify.disbandState == mjproto2.DoneWithOtherReject or
    --     msgDisbandNotify.disbandState == mjproto2.DoneWithWaitReplyTimeout or
    --         msgDisbandNotify.disbandState == mjproto2.DoneWithRoomServerNotResponse or
    --         msgDisbandNotify.disbandState == mjproto2.Done
    --  then
    --     --更新解散视图
    --     room:updateDisbandVoteView(msgDisbandNotify)
    -- elseif msgDisbandNotify.disbandState == mjproto2.ErrorDuplicateAcquire then
    -- dfCompatibleAPI:showTip("另一个玩家已经发起解散请求")
    -- elseif msgDisbandNotify.disbandState == mjproto2.ErrorNeedOwnerWhenGameNotStart then
    -- dfCompatibleAPI:showTip("牌局未开始，只有房主可以解散房间")
    end
end

return Handler
