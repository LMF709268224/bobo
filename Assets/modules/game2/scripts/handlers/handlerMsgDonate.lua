--[[
    处理服务器下发的道具捐赠
]]
local Handler = {}
Handler.VERSION = "1.0"

-- local mjproto = mjproto2

function Handler.onMsg(_, _)
    --print('llwant Donate msg')
    -- local msgDonate = mjproto.MsgDonate()
    -- msgDonate:ParseFromString(msgData)
    --
    --logError("-------------------- msgDonate item :"..tostring(msgDonate.itemID))
    --logError("-------------------- msgDonate toChairID :"..tostring(msgDonate.toChairID))
    --logError("-------------------- msgDonate fromChairID :"..tostring(msgDonate.fromChairID))
    -- room:showDonate(msgDonate)
end

return Handler
