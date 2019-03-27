--[[
    处理服务器下发的道具捐赠
]]
local Handler={}
Handler.VERSION='1.0'

local pokerfaceProto = pkproto2

function Handler:onMsg(msgData, room)
    --print('llwant Donate msg')

    local msgDonate = pokerfaceProto.MsgDonate()
    msgDonate:ParseFromString(msgData)--
    --logError("-------------------- msgDonate item :"..tostring(msgDonate.itemID))
    --logError("-------------------- msgDonate toChairID :"..tostring(msgDonate.toChairID))
    --logError("-------------------- msgDonate fromChairID :"..tostring(msgDonate.fromChairID))
    room:showDonate(msgDonate)
end

return Handler
