--[[
    处理服务器下发的发牌消息，发牌消息意味一手牌开始
]]
local Handler={}
Handler.VERSION='1.0'

function Handler:onMsg(msgData, room)
    print(' return hall msg')
    g_dataModule:SaveDataByKey("RoomInfo", room.roomInfo)
    room.isDestroy = true
end

return Handler
