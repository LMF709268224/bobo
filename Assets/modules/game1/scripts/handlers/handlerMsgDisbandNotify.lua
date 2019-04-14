--[[
    处理服务器下发的解散房间请求回复，以及房间解散状态通知
]]
local Handler = {}
Handler.VERSION = "1.0"

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

function Handler.onMsg(msgData, room)
    logger.debug(" handle disband notify")

    --先清除room的msgDisbandNotify
    room.disbandLocked = false

    local msgDisbandNotify = proto.decodeMessage("pokerface.MsgDisbandNotify", msgData)
    local disbandStateEnum = proto.pokerface.DisbandState

    local ignore = {
        [disbandStateEnum.DoneWithOtherReject] = true,
        [disbandStateEnum.DoneWithWaitReplyTimeout] = true,
        [disbandStateEnum.DoneWithRoomServerNotResponse] = true,
        [disbandStateEnum.Done] = true
    }

    if msgDisbandNotify.disbandState == disbandStateEnum.Waiting then
        --保存到room到，以便重复点击申请解散按钮进而显示
        room.disbandLocked = true
        room:updateDisbandVoteView(msgDisbandNotify)
    elseif ignore[msgDisbandNotify.disbandState] then
        --elseif msgDisbandNotify.disbandState == disbandStateEnum.ErrorDuplicateAcquire then
        --dfCompatibleAPI:showTip("另一个玩家已经发起解散请求")
        --elseif msgDisbandNotify.disbandState == disbandStateEnum.ErrorNeedOwnerWhenGameNotStart then
        --dfCompatibleAPI:showTip("牌局未开始，只有房主可以解散房间")
        --更新解散视图
        room:updateDisbandVoteView(msgDisbandNotify)
    else
        logger.debug("ignore disband state:", msgDisbandNotify.disbandState)
    end
end

return Handler
