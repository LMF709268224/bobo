--[[
    封装一下BestHTTP的websocket，主要是把网络消息，网络事件
    push到消息队列中
]]
local WS = {}

local mt = {__index = WS}
local CS = _ENV.CS

local logger = require "lobby/lcore/logger"

local wsClean = function(w)
    w.OnOpen = nil
    w.OnClosed = nil
    w.OnError = nil
    w.OnMessage = nil
    w.OnPong = nil
    w.OnBinary = nil
    w.PingDataProvider = nil
end

function WS.new(url, msgQueue)
    local ws = {url = url, mq = msgQueue}
    return setmetatable(ws, mt)
end

function WS:open()
    if self.ws ~= nil then
        logger.error("websocket is already opened")
        return
    end

    local bestHTTPws = CS.NetHelper.NewWebSocket(self.url)
    self.ws = bestHTTPws
    local this = self

    bestHTTPws.OnOpen = function(ws)
        logger.debug("ws opened")
        ws.PingFrequency = 15000 -- 15秒ping一次服务器
        ws.StartPingThread = true

        this:onBestHTTPWebsocketOpen()
    end

    bestHTTPws.OnClosed = function(ws, code, msg)
        logger.debug("ws closed, code:" .. code .. ",msg:" .. msg)
        wsClean(ws)

        this:onBestHTTPWebsocketClose()
    end

    bestHTTPws.OnError = function(ws)
        logger.error("ws error")
        wsClean(ws)

        this:onBestHTTPWebsocketError()
    end

    bestHTTPws.OnMessage = function(_, text)
        this:onBestHTTPWebsocketTextMessage(text)
    end

    bestHTTPws.OnBinary = function(_, binary)
        this:onBestHTTPWebsocketBinary(binary)
    end

    bestHTTPws.OnPong = function(_, pongData)
        logger.debug("websocket recv pong data length:", #pongData)
        local ms = CS.NetHelper.TimeElapsedMilliseconds(pongData)
        this:onBestHTTPWebsocketPong(ms)
    end

    bestHTTPws.PingDataProvider = function()
        local pingData = CS.NetHelper.CurrentUTCTime2Bytes()
        logger.debug("ping data length:", #pingData)
        return pingData
    end

    -- 开始连接服务器
    bestHTTPws:Open()
end

function WS:close()
    self.ws:Close()
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
    logger.debug("ws text msg:" .. text)
    self.mq:pushWebsocketTextMessageEvent(text)
end

function WS:onBestHTTPWebsocketBinary(binary)
    logger.debug("ws binary msg, length:" .. #binary)
    self.mq:pushWebsocketBinaryEvent(binary)
end

function WS:onBestHTTPWebsocketPong(ms)
    --self.mq:pushWebsocketPongEvent(ms)
    logger.debug("ws recv pong ms:", ms)
    self.ms = ms
end

return WS
