--[[
外面调用getSingleton获得唯一实例单件
]]
--luacheck: no self
local SG = {}

local mt = {__index = SG}

local websocket = require "scripts/websocket"
local msgQueue = require "scripts/msgQueue"
local logger = require "lobby/lcore/logger"
local proto = require "scripts/proto/proto"
local room = require "scripts/room"
local fairy = require "lobby/lcore/fairygui"
local dialog = require "lobby/lcore/dialog"
local urlPaths = require "lobby/lcore/urlpathsCfg"
local CS = _ENV.CS

local singleTon = nil

function SG.getSingleton()
    if singleTon ~= nil then
        return singleTon
    else
        local s = {}
        singleTon = setmetatable(s, mt)

        return singleTon
    end
end

-----------------------------------
--尝试进入房间
--函数最末会调用destroyWebsocket确保
--websocket彻底销毁
--@param myUser 用户对象，至少包含userID
-----------------------------------
function SG:tryEnterRoom(serverUUID, myUser, roomInfo)
    self.isEnterRoom = true

    assert(serverUUID, "SG:tryEnterRoom, serverUUID must not be null")
    assert(myUser, "SG:tryEnterRoom, myUser must not be null")
    assert(roomInfo, "SG:tryEnterRoom, roomInfo must not be null")

    --测试用
    local host = _ENV.thisMod:CallLobbyStringFunc("gameServerSchemeFD")
    local tk = CS.UnityEngine.PlayerPrefs.GetString("token", "")
    local url
    local rID = roomInfo.roomID
    local uID = myUser.userID

    url = host .. string.format(urlPaths.gameWebsocketPlay, serverUUID) .. "?userID=" .. uID .. "&roomID=" .. rID
    url = url .. "&tk=" .. tk

    logger.debug(" tryEnterRoom, url:", url)

    --保存一下，以便重连时使用
    self.url = url
    self.myUser = myUser
    self.ws = nil
    self.connectErrorCount = 0

    --while循环是考虑到，断线重连情况下，需要重新进入doEnterRoom
    while true do
        self:doEnterRoom(url, myUser, roomInfo)
        logger.debug("doEnterRoom return, retry:", self.retry, ", forceExit:", self.forceExit)

        self.connectErrorCount = self.connectErrorCount + 1
        -- 等3秒重连
        -- self:waitSecond(3)
        -- 确保websocket消息队列销毁，以及websocket彻底销毁
        if self.ws ~= nil then
            local ws = self.ws
            self.ws = nil
            ws:close()
        end

        if not self.retry or self.forceExit then
            break
        end
    end

    self.isEnterRoom = false
    --解开引用room对象
    if self.room ~= nil then
        self.room = nil
    end

    logger.debug(" -------destory room complete-------")
    self:backToLobby()
end

function SG:backToLobby()
    -- 清理界面
    fairy.GRoot.inst:CleanupChildren()
    -- 退回大厅
    _ENV.thisMod:BackToLobby()
end

function SG:doEnterRoom(url, myUser, roomInfo)
    logger.info("doEnterRoom enter---")
    -- 每次进入本函数时都重置retry为false
    -- 如果发生断线重连且用户选择了重连那么后面的代码
    -- 会置retry为true
    self.retry = false
    self.isTokenExpire = false

    -- self.room可能不为nil，因为如果断线重入，room以及roomview就可能已经加载
    if self.room == nil then
        self:createRoom(myUser, roomInfo)
    end

    -- 显示登录房间等待进度框
    -- 显示于界面的等待信息
    local showProgressTips = "正在进入房间"

    -- 构建websocket
    local mq = msgQueue.new()
    local ws = websocket.new(url, mq, self.room.roomView.unityViewNode)

    self.mq = mq
    self.ws = ws
    ws:open() -- 连接服务器

    -- 连接，并等待连接完成
    local rt = self:waitConnect(showProgressTips)

    local enterRoomReplyMsg
    local enterRoomResult

    if rt ~= 0 then
        -- 连接超时提示和处理（用户选择是否重连，重连的话下一帧重新执行tryEnterRoom
        self.retry = true
        if self.connectErrorCount > 0 then
            self:showRetryMsgBox()
        end
        return
    else
        logger.debug("waitWebsocketMessage wait room reply")
        enterRoomReplyMsg = self:waitWebsocketMessage(showProgressTips)
    end

    if enterRoomReplyMsg == nil then
        -- 连接超时提示和处理（用户选择是否重连，重连的话下一帧重新执行tryEnterRoom）
        logger.debug(" waitWebsocketMessage return nil")
        self.retry = true
        if self.connectErrorCount > 0 then
            self:showRetryMsgBox()
        end
        return
    end

    enterRoomResult = proto.decodeMessage("mahjong.MsgEnterRoomResult", enterRoomReplyMsg.Data)

    if enterRoomResult == nil then
        -- 解码错误，已经在decodeEnterRoomResult中进行错误处理
        -- 这种情况就不进行重入了，把websocket关闭，回大厅
        -- 关闭连接
        logger.debug(" enterRoomResult is nil")
        return
    end

    logger.debug(" server reply enter room status:", enterRoomResult.status)
    if enterRoomResult.status ~= 0 then
        -- 进入房间错误提示
        logger.debug(" server return enter room ~= 0")
        self:showEnterRoomError(enterRoomResult.status)
        return
    end

    self:pumpMsg()

    logger.info("doEnterRoom leave---")
end

function SG:createRoom(myUser, roomInfo)
    self.room = room.new(myUser)
    self.room.host = self
    self.room.roomInfo = roomInfo
    self.room:loadRoomView()
    self.isEnterRoom = false
end

function SG:pumpMsg()
    while true do
        local mq = self.mq
        local msg = mq:getMsg()
        if msg.mt == msgQueue.MsgType.quit then
            -- quit
            break
        end

        if msg.mt == msgQueue.MsgType.wsData then
            -- 分派websocket消息
            self.room:dispatchWeboscketMessage(msg.data)
        elseif msg.mt == msgQueue.MsgType.wsClosed or msg.mt == msgQueue.MsgType.wsError then
            logger.debug(" websocket connection has broken")
            if self.room.isDestroy then
                -- 用户主动离开房间，不再做重入
                logger.debug(" room has been destroy")
                break
            end
            -- 网络连接断开，重新登入
            self:showRetryMsgBox("与游戏服务器连接断开，是否重连？")
            -- 网络连接断开时关闭申请解散框
            --self.room:destroyVoteView()
            self.retry = true
            if self.connectErrorCount > 2 then
                self:showRetryMsgBox()
            end
            break
        end
    end
end

------------------------------------------
--等待服务器的消息（主要是等待服务器的进入房间回复）
--如果超时，则认为连接断开
------------------------------------------
function SG:waitWebsocketMessage(showProgressTips)
    logger.debug("SG:waitWebsocketMessage, ", showProgressTips)

    local msg = self.mq:getMsg()

    if msg.mt == msgQueue.MsgType.wsData then
        return msg.data
    else
        logger.error("expected normal websocket msg, but got:", msg)
    end

    return nil
end

------------------------------------------
--等待连接服务器完成，注意这里没有使用超时时间
--需要c# websocket设置tcpclient的链接超时时间
--以避免等待过于长久
------------------------------------------
function SG:waitConnect(showProgressTips)
    logger.debug("SG:waitConnect, ", showProgressTips)

    local msg = self.mq:getMsg()

    logger.debug("SG:waitConnect, mq:getMsg return:", msg)

    if msg.mt == msgQueue.MsgType.wsOpen then
        return 0
    end

    return -1
end

---------------------------------------
--显示重连对话框，如果用户选择重试
--则return true，否则返回false
---------------------------------------
function SG:showRetryMsgBox(msg)
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

---------------------------------------
--显示进入房间的错误信息
---------------------------------------
function SG:showEnterRoomError(status)
    local msg = proto.getEnterRoomErrorCode(status)
    logger.warn("enter room failed, server return error：", msg)
    dialog.coShowDialog(
        msg,
        function()
            self.retry = false
        end,
        nil
    )
end

------------------------------------------
--向游戏服务器发送ready消息
------------------------------------------
function SG:sendPlayerReadyMsg()
    -- local gmsg = pokerfaceProto.GameMessage()
    -- gmsg.Ops = pokerfaceProto.OPPlayerReady

    -- local buf = gmsg:SerializeToString()

    local gmsg = {}
    gmsg.Ops = proto.mahjong.MessageCode.OPPlayerReady
    local buf = proto.encodeMessage("mahjong.GameMessage", gmsg)
    self.ws:sendBinary(buf)
end

------------------------------------------
--向游戏服务器发送离开房间消息
------------------------------------------
function SG:sendLeaveRoomMsg()
    -- local gmsg = pokerfaceProto.GameMessage()
    -- gmsg.Ops = pokerfaceProto.OPPlayerLeaveRoom

    -- local buf = gmsg:SerializeToString()
    local gmsg = {}
    gmsg.Ops = proto.mahjong.MessageCode.OPPlayerLeaveRoom
    local buf = proto.encodeMessage("mahjong.GameMessage", gmsg)
    self.ws:sendBinary(buf)
end

function SG:tryEnterReplayRoom(userID, msgAccLoadReplayRecord, chairID)
    --local pkproto2 = game_mahjong_s2s_pb
    local msgHandRecord = proto.decodeMessage("mahjong.SRMsgHandRecorder", msgAccLoadReplayRecord.replayRecordBytes)

    --把配置内容替换配置ID，兼容老代码
    msgHandRecord.roomConfigID = msgAccLoadReplayRecord.roomJSONConfig

    logger.debug(" sr-actions count:", #msgHandRecord.actions)
    --如果不提供userID,则必须提供chairID，然后根据chairID获得userID
    if not userID then
        logger.debug(" userID is nil, use chairID to find userID")
        for _, player in ipairs(msgHandRecord.players) do
            if player.chairID == chairID then
                userID = player.userID
                break
            end
        end
    end

    local prompt = require "lobby/lcore/prompt"
    if userID == nil then
        -- 根据chairID获取不到userID，说明输入的回放码不正确或已过期
        prompt.showPrompt("您输入的回放码不存在,或录像已过期!")
        return
    else
        logger.debug(" tryEnterReplayRoom userID ", userID)
    end

    self.user = {userID = userID}
    local replay = require "scripts/replay"
    local rp = replay.new(self, msgHandRecord)

    --新建room和绑定roomView
    self.room = room.new(self.user, rp)
    self.room.host = self

    local roomInfo = {}
    roomInfo.roomID = ""
    roomInfo.roomNumber = msgHandRecord.roomNumber
    roomInfo.gameServerURL = ""
    roomInfo.state = 1
    roomInfo.config = msgHandRecord.roomConfigID
    roomInfo.timeStamp = ""
    roomInfo.handStartted = msgHandRecord.handNum
    roomInfo.lastActiveTime = 0
    self.room.roomInfo = roomInfo

    self.room.handStartted = msgHandRecord.handNum
    self.room.roomNumber = msgHandRecord.roomNumber
    self.room:loadRoomView()

    rp:gogogo()

    self:backToLobby()
end

return SG
