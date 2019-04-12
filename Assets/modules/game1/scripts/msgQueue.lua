--[[
    消息队列

    getMsg时如果当前没有消息，则会挂起coroutine
]]
local MQ = {}

local mt = {__index = MQ}

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

local MsgType = {wsOpen = 1, wsClosed = 2, wsError = 3, wsData = 4, quit = 5}
local mc = proto.pokerface.MessageCode
local priorityMap = {[mc.OPDisbandRequest] = 1, [mc.OPDisbandNotify] = 1, [mc.OPDisbandAnswer] = 1}

MQ.MsgType = MsgType

function MQ.new()
    local mq = {messages = {}}
    mq.priority = 0

    return setmetatable(mq, mt)
end

function MQ:getMsg()
    if #(self.messages) > 0 then --(如果消息列表里面有消息，则不挂起等待)
        return table.remove(self.messages, 1) --返回并删除列表里第一个消息
    end

    self.waitCoroutine = coroutine.running()
    coroutine.yield()
    self.waitCoroutine = nil

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
    -- 所有二进制数据包约定是GameMessage类型的proto 消息
    local gmsg = proto.decodeGameMessage(binary)
    local msg = {mt = MsgType.wsData, data = gmsg}
    self:pushMsg(msg)
end

function MQ:pushQuit()
    local msg = {mt = MsgType.quit}
    self:pushMsg(msg)
end

function MQ:pushMsg(msg)
    table.insert(self.messages, msg)

    local wakeup = true
    if (self.priority > 0) then
        wakeup = false
        if msg.mt == MsgType.wsData then
            local p = priorityMap[msg.data.Ops]
            if p ~= nil and p > self.priority then
                wakeup = true
            end
        end
    end

    if wakeup then
        self:wakeupCoroutine()
    end
end

function MQ:blockNormal()
    self.priority = 1
end

function MQ:unblockNormal()
    self.priority = 0

    if #(self.messages) > 0 then
        self:wakeupCoroutine()
    end
end

function MQ:wakeupCoroutine()
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
