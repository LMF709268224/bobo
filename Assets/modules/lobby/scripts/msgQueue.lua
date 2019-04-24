--[[
    消息队列

    getMsg时如果当前没有消息，则会挂起coroutine
]]
local MQ = {}

local mt = {__index = MQ}

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

local MsgType = {wsOpen = 1, wsClosed = 2, wsError = 3, wsData = 4, quit = 5}
-- local mc = proto.pokerface.MessageCode
-- local priorityMap = {[mc.OPDisbandRequest] = 1, [mc.OPDisbandNotify] = 1, [mc.OPDisbandAnswer] = 1}

MQ.MsgType = MsgType

function MQ.new()
    local mq = {messages = {}}
    mq.priority = 0
    mq.blockedMsgs = {}

    return setmetatable(mq, mt)
end

function MQ:getMsg()
    if #(self.messages) > 0 then --(如果消息列表里面有消息，则不挂起等待)
        return table.remove(self.messages, 1) --返回并删除列表里第一个消息
    end

    self.waitCoroutine = coroutine.running()
    coroutine.yield()
    self.waitCoroutine = nil

    assert(#self.messages > 0, "getMsg coroutine been resume with empty msg")

    return table.remove(self.messages, 1) --返回并删除列表里第一个消息
end

function MQ:pushWebsocketOpenEvent()
    local msg = {mt = MsgType.wsOpen}
    self:pushMsg(msg)
end

function MQ:pushWebsocketCloseEvent()
    local msg = {mt = MsgType.wsClosed}
    self:pushMsg(msg)
end

function MQ:pushWebsocketErrorEvent()
    local msg = {mt = MsgType.wsError}
    self:pushMsg(msg)
end

function MQ:pushWebsocketTextMessageEvent(text)
    local msg = {mt = MsgType.wsData, data = text}
    self:pushMsg(msg)
end

function MQ:pushWebsocketBinaryEvent(binary)
    -- 所有二进制数据包约定是LobbyMessage类型的proto 消息
    local lobbyMsg = proto.decodeMessage("lobby.LobbyMessage", binary)
    local msg = {mt = MsgType.wsData, data = lobbyMsg}
    self:pushMsg(msg)
end

function MQ:pushQuit()
    local msg = {mt = MsgType.quit}
    self:pushMsg(msg)
end

function MQ:pushMsg(msg)
    table.insert(self.messages, msg)
    self:wakeupCoroutine()
end

function MQ:wakeupCoroutine()
    assert(#self.messages > 0, "wakeupCoroutine without any msg")
    if self.waitCoroutine ~= nil then
        local waitCoroutine = self.waitCoroutine
        self.waitCoroutine = nil
        local r, err = coroutine.resume(waitCoroutine)
        if not r then
            logger.error(debug.traceback(waitCoroutine, err))
        end
    end
end

return MQ
