--[[
    处理服务器下发的通知各个玩家，房间已经被解散，或者被删除
]]

local Handler={}
Handler.VERSION='1.0'
local dfPath = "GuanZhang/Script/"
local dfCompatibleAPI = require(dfPath ..'dfMahjong/dfCompatibleAPI')

function Handler:onMsg(msgData, room)
    --print(' room deleted msg')

    local msgKickoutResult = pkproto2.MsgKickoutResult()
    msgKickoutResult:ParseFromString(msgData)

    local msg = ""
    if msgKickoutResult.result == pkproto2.KickoutResult_Success then
        if msgKickoutResult.victimUserID == room:me().userID then
            --自己被踢
            room.isDestroy = true
            msg = "您被房主["..msgKickoutResult.byWhoNick.."]踢出房间"
            dfCompatibleAPI:closeDialog()
            local waitCo = coroutine.running()

            --openDialog 只有确定按钮
            --showMessageBox 有确定 取消两个按钮

            dfCompatibleAPI:openDialog(
            msg,
            function()
                local flag, msg2 =  coroutine.resume(waitCo)
                if not flag then
                    logError(msg2)
                    return
                end
            end
            )

            coroutine.yield()
            return
        elseif msgKickoutResult.byWhoUserID == room:me().userID then
            --自己踢别人
            msg = "玩家["..msgKickoutResult.victimNick.."]已经被踢出房间"
        else
            --房主踢了其他人
            msg = "玩家["..msgKickoutResult.victimNick.."]被房主["..msgKickoutResult.byWhoNick.."]踢出房间"
        end
    elseif msgKickoutResult.result == pkproto2.KickoutResult_FailedGameHasStartted then
        msg = "游戏已经开始，不能踢出玩家"
    elseif msgKickoutResult.result == pkproto2.KickoutResult_FailedNeedOwner then
        msg = "只有房主才可以踢出玩家"
    elseif msgKickoutResult.result == pkproto2.KickoutResult_FailedPlayerNotExist then
        msg = "踢出用户失败，该玩家已离开"
    end

    if msg ~= "" then
        print(" kickout:"..msg)
        dfCompatibleAPI:showTip(msg)
    end

end

return Handler
