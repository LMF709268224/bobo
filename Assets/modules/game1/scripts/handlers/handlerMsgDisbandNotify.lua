--[[
    处理服务器下发的解散房间请求回复，以及房间解散状态通知
]]
local Handler={}
Handler.VERSION='1.0'
local dfPath = "GuanZhang/Script/"
local dfCompatibleAPI = require(dfPath ..'dfMahjong/dfCompatibleAPI')

function Handler:onMsg(msgData, room)
    --print(' handle disband notify')

    --先清除room的msgDisbandNotify
    room.disbandLocked = false

    local msgDisbandNotify = pkproto2.MsgDisbandNotify()
    msgDisbandNotify:ParseFromString(msgData)

    if msgDisbandNotify.disbandState == pkproto2.Waiting then
        --保存到room到，以便重复点击申请解散按钮进而显示
        room.disbandLocked = true
        room:updateDisbandVoteView(msgDisbandNotify)
    elseif msgDisbandNotify.disbandState == pkproto2.DoneWithOtherReject or
        msgDisbandNotify.disbandState == pkproto2.DoneWithWaitReplyTimeout or
        msgDisbandNotify.disbandState == pkproto2.DoneWithRoomServerNotResponse or
        msgDisbandNotify.disbandState == pkproto2.Done then

        --更新解散视图
        room:updateDisbandVoteView(msgDisbandNotify)
    elseif msgDisbandNotify.disbandState == pkproto2.ErrorDuplicateAcquire then
        dfCompatibleAPI:showTip("另一个玩家已经发起解散请求")
    elseif msgDisbandNotify.disbandState == pkproto2.ErrorNeedOwnerWhenGameNotStart then
        dfCompatibleAPI:showTip("牌局未开始，只有房主可以解散房间")
    end
end

return Handler
