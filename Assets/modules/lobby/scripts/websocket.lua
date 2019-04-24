--[[
    封装一下BestHTTP的websocket，主要是把网络消息，网络事件
    push到消息队列中
]]
local WS = {}

local mt = {__index = WS}
local CS = _ENV.CS

local logger = require "lobby/lcore/logger"
local httpHelper = require "lobby/lcore/httpHelper"

function WS.new(url, msgQueue, comp)
    logger.debug("url:", url)
    local ws = {url = url, mq = msgQueue, comp = comp}
    return setmetatable(ws, mt)
end

function WS:open()
    if self.ws ~= nil then
        logger.error("websocket is already opened")
        return
    end

    local reqWrapper = httpHelper.websocket(self.comp, self.url)
    local bestHTTPws = reqWrapper.ws
    self.ws = bestHTTPws
    self.reqWrapper = reqWrapper
    local this = self

    bestHTTPws.OnOpen = function(ws)
        logger.debug("ws opened")
        local timespan = CS.System.TimeSpan.FromDays(1) -- 一天都不关闭，BestHTTP默认是10秒
        ws.CloseAfterNoMesssage = timespan
        ws.PingFrequency = 15000 -- 15秒ping一次服务器
        ws.StartPingThread = true

        this:onBestHTTPWebsocketOpen()
    end

    bestHTTPws.OnClosed = function(_, code, msg)
        logger.debug("ws closed, code:", code, ",msg:", msg)
        httpHelper.cleanWebsocket(reqWrapper)

        this:onBestHTTPWebsocketClose()
    end

    bestHTTPws.OnError = function(_)
        logger.debug("ws error")
        httpHelper.cleanWebsocket(reqWrapper)

        this:onBestHTTPWebsocketError()
    end

    bestHTTPws.OnMessage = function(_, text)
        this:onBestHTTPWebsocketTextMessage(text)
    end

    bestHTTPws.OnBinary = function(_, binary)
        this:onBestHTTPWebsocketBinary(binary)
    end

    -- 开始连接服务器
    bestHTTPws:Open()
end

function WS:close()
    if self.reqWrapper ~= nil then
        self.reqWrapper.ws:Close()
        httpHelper.cleanWebsocket(self.reqWrapper)
        self.reqWrapper = nil
    end
end

function WS:onBestHTTPWebsocketOpen()
    self.mq:pushWebsocketOpenEvent()
end

function WS:onBestHTTPWebsocketClose()
    self.mq:pushWebsocketCloseEvent()
end

function WS:onBestHTTPWebsocketError()
    self.mq:pushWebsocketErrorEvent()
end

function WS:onBestHTTPWebsocketTextMessage(text)
    logger.debug("ws text msg:", text)
    self.mq:pushWebsocketTextMessageEvent(text)
end

function WS:onBestHTTPWebsocketBinary(binary)
    logger.debug("ws binary msg, length:", #binary)
    self.mq:pushWebsocketBinaryEvent(binary)
end

function WS:sendBinary(msg)
    self.ws:SendBinary(msg)
end

return WS
