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
    local isBlocked = false
    if (self.priority > 0) then
        isBlocked = true
        if msg.mt == MsgType.wsData then
            local p = priorityMap[msg.data.Ops]
            if p ~= nil and p >= self.priority then
                isBlocked = false
            end
        end
    end

    if not isBlocked then
        table.insert(self.messages, msg)
        self:wakeupCoroutine()
    else
        table.insert(self.blockedMsgs, msg)
    end
end

function MQ:blockNormal()
    self.priority = 1
    logger.debug("MQ:blockNormal")
    -- 如果此时消息队列有消息，需要把消息迁移到
    -- blocked 队列中
    if #self.messages > 0 then
        logger.debug("MQ:blockNormal, current msg count:", #self.messages)
        local unblockedMsgs = {}
        for _, msg in ipairs(self.messages) do
            local isBlocked = true
            if msg.mt == MsgType.wsData then
                local p = priorityMap[msg.data.Ops]
                if p ~= nil and p >= self.priority then
                    isBlocked = false
                end
            end

            if isBlocked then
                table.insert(self.blockedMsgs, msg)
            else
                table.insert(unblockedMsgs, msg)
            end
        end

        self.messages = unblockedMsgs
        logger.debug("MQ:blockNormal, after migrate, msg count:", #self.messages)
    end
end

function MQ:unblockNormal()
    self.priority = 0

    if #self.blockedMsgs > 0 then
        for _, msg in ipairs(self.blockedMsgs) do
            table.insert(self.messages, msg)
        end
        self.blockedMsgs = {}
        self:wakeupCoroutine()
    end
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
