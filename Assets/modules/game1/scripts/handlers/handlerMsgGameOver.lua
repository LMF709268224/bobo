--[[
    处理服务器下发的一手牌结束的消息
    一手牌结束后分数结算
]]
local Handler={}
Handler.VERSION='1.0'

local pokerfaceProto = pkproto2

function Handler:onMsg(msgData, room)
    --print('llwant game over msg')

    --TODO: 显示结算界面
    --在此时，服务器已经解散了房间，因此客户端会收到房间解散消息
    --服务器跟着也断开客户端的websocket连接，因此客户端需要避免多次弹出
    --如“房间已经被解散”，“与服务器断开连接，是否重连”之类的框框

    --

    local msgGameOver = pokerfaceProto.MsgGameOver()
    msgGameOver:ParseFromString(msgData)
    --把结果保存到 room
    room.msgGameOver = msgGameOver
    --显示游戏最后结果()
    room:loadGameOverResultView()
end

return Handler
