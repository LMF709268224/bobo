--[[
    处理服务器下发要求客户端显示一个tips的消息
]]

local Handler={}
Handler.VERSION='1.0'
local dfPath = "GuanZhang/Script/"
local dfCompatibleAPI = require(dfPath ..'dfMahjong/dfCompatibleAPI')

function Handler:onMsg(msgData, room)
    --print(' room show tips msg')

    local msgRoomShowTips = pkproto2.MsgRoomShowTips()
    msgRoomShowTips:ParseFromString(msgData)

    if msgRoomShowTips.tipCode == pkproto2.TCNone then
        print('<<<'..msgRoomShowTips.tips..'>>>')
        dfCompatibleAPI:showTip(""..msgRoomShowTips.tips)
    elseif msgRoomShowTips.tipCode == pkproto2.TCWaitOpponentsAction then
        --ViewManager.ShowTip("正在等待其他玩家操作")
    elseif msgRoomShowTips.tipCode == pkproto2.TCDonateFailedNoEnoughDiamond then
        dfCompatibleAPI:showTip("打赏失败，钻石不足")
    end
end

return Handler
