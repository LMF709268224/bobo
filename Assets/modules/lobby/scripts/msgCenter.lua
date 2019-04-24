
--[[
外面调用getSingleton获得唯一实例单件
]]
--luacheck: no self
local MsgCenter = {}

local mt = {__index = MsgCenter}

local websocket = require "scripts/websocket"
local msgQueue = require "scripts/msgQueue"
local logger = require "lobby/lcore/logger"
-- local proto = require "scripts/proto/proto"
local dialog = require "lobby/lcore/dialog"

function MsgCenter:new(url, component)
    local msgCenter = {url = url, component = component}

    msgCenter.connectErrorCount = 0

    return setmetatable(msgCenter, mt)
end

function MsgCenter:start()
    while true do

        self:connectServer()

        logger.debug("MsgCenter, retry:", self.retry)

        self.connectErrorCount = self.connectErrorCount + 1
        -- 等3秒重连
        -- self:waitSecond(3)
        -- 确保websocket消息队列销毁，以及websocket彻底销毁
        if self.ws ~= nil then
            local ws = self.ws
            self.ws = nil
            ws:close()
        end

        if not self.retry then
            break
        end
    end
end

function MsgCenter:connectServer()
    logger.debug("connectServer:", self.url)
    local mq = msgQueue.new()
    local ws = websocket.new(self.url, mq, self.component)

    self.mq = mq
    self.ws = ws

    ws:open() -- 连接服务器

    -- 连接，并等待连接完成
    local rt = self:waitConnect()
    if rt ~= 0 then
        -- 连接超时提示和处理（用户选择是否重连，重连的话下一帧重新执行tryEnterRoom
        self.retry = true
        if self.connectErrorCount > 0 then
            self:showRetryMsgBox()
        end
        return
    end

    logger.debug("connect success")

    self:pumpMsg()
end

function MsgCenter:pumpMsg()
    while true do
        local mq = self.mq
        local msg = mq:getMsg()
        if msg.mt == msgQueue.MsgType.quit then
            -- quit
            break
        end

        if msg.mt == msgQueue.MsgType.wsData then
            -- 分派websocket消息
            self:dispatchWeboscketMessage(msg.data)
        elseif msg.mt == msgQueue.MsgType.wsClosed or msg.mt == msgQueue.MsgType.wsError then
            logger.debug(" websocket connection has broken")

            self.retry = true
            if self.connectErrorCount > 2 then
                self:showRetryMsgBox("与游戏服务器连接断开，是否重连？")
            end
            break
        end
    end
end

------------------------------------------
--等待连接服务器完成，注意这里没有使用超时时间
--需要c# websocket设置tcpclient的链接超时时间
--以避免等待过于长久
------------------------------------------
function MsgCenter:waitConnect()
    logger.debug("MsgCenter:waitConnect")

    local msg = self.mq:getMsg()

    logger.debug("MsgCenter:waitConnect, mq:getMsg return:", msg)

    if msg.mt == msgQueue.MsgType.wsOpen then
        return 0
    end

    return -1
end


---------------------------------------
--显示重连对话框，如果用户选择重试
--则return true，否则返回false
---------------------------------------
function MsgCenter:showRetryMsgBox(msg)
    msg = msg or "连接游戏服务器失败，是否重连？"
    dialog.coShowDialog(
        msg,
        function()
            self.retry = true
        end,
        function()
            self.retry = false
        end
    )
end

function MsgCenter:dispatchWeboscketMessage(lobbyMessage)
    logger.debug("msgCenter.dispatchWeboscketMessage Ops:", lobbyMessage.Ops)
    -- TODO: 分发到对应的handle去
end

return MsgCenter
