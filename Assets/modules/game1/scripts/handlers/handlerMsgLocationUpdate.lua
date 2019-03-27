--[[
    处理服务器下发要求客户端显示一个tips的消息
]]

local Handler={}
Handler.VERSION='1.0'

function Handler:onMsg(msgData, room)
    print(' update user gps')

    local msgUpdateLocation = pokerfaceProto.MsgUpdateLocation()
    msgUpdateLocation:ParseFromString(msgData)
    room:updatePlayerLocation(msgUpdateLocation)
end

return Handler
