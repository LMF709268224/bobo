--[[
外面调用getSingleton获得唯一实例单件
]]
local DF = {}

local mt = {__index = DF}

local websocket = require "scripts/websocket"
local msgQueue = require "scripts/msgQueue"
local logger = require "lobby/lcore/logger"
local proto = require "scripts/proto/proto"
local room = require "scripts/room"
local fairy = require "lobby/lcore/fairygui"
local dialog = require "lobby/dialog"

local singleTon = nil

function DF.getSingleton()
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
function DF:tryEnterRoom(url, myUser, roomInfo)
    self.isEnterRoom = true

    --logger.debug(" tryEnterRoom, date2: "..os.date().. ", timeStamp:"..os.time()..", clock:"..os.clock())
    --测试用
    url = url or "ws://localhost:3001/prunfast/uuid/ws/monkey?userID=6&roomID=monkey-room"

    logger.debug(" tryEnterRoom, url:" .. url)

    myUser = myUser or {userID = "6"}

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

    if self.forceExit then
        self:logout()
    elseif self.isTokenExpire then
        self:logout("登录超时，请重新登录")
    end
    self.forceExit = false
    -- self.locked = false

    logger.debug(" -------destory room complete-------")

    -- 清理界面
    fairy.GRoot.inst:CleanupChildren()
    -- 退回大厅
    _ENV.thisMod:BackToLobby()
end

function DF:doEnterRoom(url, myUser, roomInfo)
    -- 每次进入本函数时都重置retry为false
    -- 如果发生断线重连且用户选择了重连那么后面的代码
    -- 会置retry为true
    self.retry = false
    self.isTokenExpire = false
    -- 显示登录房间等待进度框
    -- 显示于界面的等待信息
    local showProgressTips = "正在进入房间"

    -- 构建websocket
    local mq = msgQueue.new()
    local ws = websocket.new(url, mq)

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

    enterRoomResult = proto.decodeMessage("pokerface.MsgEnterRoomResult", enterRoomReplyMsg.Data)

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

    -- self.room可能不为nil，因为如果断线重入，room以及roomview就可能已经加载
    if self.room == nil then
        self:createRoom(myUser, roomInfo)
    end

    self:pumpMsg()

    logger.debug(" end room main-msg-loop")
end

function DF:createRoom(roomInfo)
    self.room = room.new(self.myUser)
    self.room.host = self
    self.room.roomInfo = roomInfo
    self.room:loadRoomView()
    self.isEnterRoom = false
end

function DF:pumpMsg()
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
            self.room:destroyVoteView()
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
function DF:waitWebsocketMessage(showProgressTips)
    logger.debug("DF:waitWebsocketMessage, " .. showProgressTips)

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
function DF:waitConnect(showProgressTips)
    logger.debug("DF:waitConnect, " .. showProgressTips)

    local msg = self.mq:getMsg()

    logger.debug("DF:waitConnect, mq:getMsg return:", msg)

    if msg.mt == msgQueue.MsgType.wsOpen then
        return 0
    end

    return -1
end

---------------------------------------
--显示重连对话框，如果用户选择重试
--则return true，否则返回false
---------------------------------------
function DF:showRetryMsgBox(msg)
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
function DF:showEnterRoomError(status)
    local msg = proto.getEnterRoomErrorCode(status)
    logger.warn("进入房间失败，服务器返回错误：", msg)
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

------------------------------------------
--向游戏服务器发送ready消息
------------------------------------------
function DF:sendPlayerReadyMsg()
    -- local gmsg = pokerfaceProto.GameMessage()
    -- gmsg.Ops = pokerfaceProto.OPPlayerReady

    -- local buf = gmsg:SerializeToString()

    local gmsg = {}
    gmsg.Ops = proto.pokerface.MessageCode.OPPlayerReady
    local buf = proto.encodeMessage("pokerface.GameMessage", gmsg)
    self.ws:sendBinary(buf)
end

------------------------------------------
--向游戏服务器发送离开房间消息
------------------------------------------
function DF:sendLeaveRoomMsg()
    -- local gmsg = pokerfaceProto.GameMessage()
    -- gmsg.Ops = pokerfaceProto.OPPlayerLeaveRoom

    -- local buf = gmsg:SerializeToString()
    local gmsg = {}
    gmsg.Ops = proto.pokerface.MessageCode.OPPlayerLeaveRoom
    local buf = proto.encodeMessage("pokerface.GameMessage", gmsg)
    self.ws:sendBinary(buf)
end

------------------------------------------
--向websocket投递退出房间事件
--这样weboscket就会即刻唤醒我们的消息coroutine
------------------------------------------
function DF:triggerLeaveRoom()
    if self.ws ~= nil then
        self.ws:raiseEvent(websocket.exitRoomEvent)
    end
end

function DF:registerWakeupWSMsg(filterFunc)
    if self.ws ~= nil then
        logger.debug(" registerWakeupWSMsg")
        self.ws:registerMsgFilter(filterFunc)
    end
end

function DF:unRegisterWakeupWSMsg()
    if self.ws ~= nil then
        logger.debug(" unRegisterWakeupWSMsg")
        self.ws:unRegisterMsgFilter()
    end
end

------------------------------------------
--向websocket投递超时事件
--这样weboscket就会即刻唤醒我们的消息coroutine
------------------------------------------
function DF:triggerTimeout()
    if self.ws ~= nil then
        self.ws:raiseEvent(websocket.timeoutEvent)
    end
end

------------------------------------------
--执行退出房间流程：
--向服务器发送退出房间请求，并等待回复
--如果超时而未能收到服务器回复，直接回到大厅
------------------------------------------
function DF:doLeaveRoom()
    --先向服务器发送离开请求
    self:sendLeaveRoomMsg()
    -- local df = self

    -- local showProgressTips = "正请求服务器离开房间..."
    -- --显示等待滚动圈
    -- dfCompatibleAPI:showWaitTip(
    --     showProgressTips,
    --     5,
    --     function()
    --         df:triggerTimeout()
    --     end,
    --     0
    -- )
    local canLeave = true
    --等待服务器回复
    while true do
        local ws = self.ws
        local result = ws:waitWebsocketMessageEx()
        if result.ev == websocket.websocketEvent then
            local msg = result.data
            if msg == nil then
                -- 网络连接断开,break循环
                break
            else
                -- 如果不是OPPlayerLeaveRoom，则抛弃消息继续等待
                if pokerfaceProto.OPPlayerLeaveRoom == msgHelper.decodeMessageCode(msg) then
                    --等到服务器的回复，终止循环
                    local leaveReplyMsg = msgHelper:decodeEnterRoomResult(msg)
                    if leaveReplyMsg ~= nil and leaveReplyMsg.status ~= 0 then
                        canLeave = false
                    -- dfCompatibleAPI:showTip("游戏已经开始或者房间正在申请解散，不能退出")
                    end
                    break
                end
            end
        elseif result.ev == websocket.timeoutEvent then
            --超时了，由于滚动圈超时回调，把timeout event放到websocket上导致其返回
            --因此终止循环
            break
        end
    end

    --关闭滚动圈
    -- g_commonModule:CloseWaitTip()
    return canLeave
end

function DF:tryEnterReplayRoom(userID, msgAccLoadReplayRecord, chairID)
    -- if self.locked then
    --     logger.debug(" df is locked")
    --     return
    -- end
    if self:isRoomViewExit() then
        logger.debug(" tryEnterReplayRoom error: dafeng room view is exit")
        return
    end

    --local pkproto2 = game_mahjong_s2s_pb
    local msgHandRecorder = pokerfaceS2s.SRMsgHandRecorder()
    msgHandRecorder:ParseFromString(msgAccLoadReplayRecord.replayRecordBytes)

    --把配置内容替换配置ID，兼容老代码
    msgHandRecorder.roomConfigID = msgAccLoadReplayRecord.roomJSONConfig

    logger.debug(" sr-actions count:" .. #msgHandRecorder.actions)
    local isShare = false
    --如果不提供userID,则必须提供chairID，然后根据chairID获得userID
    if not userID then
        isShare = true
        logger.debug(" userID is nil, use chairID to find userID")
        for _, player in ipairs(msgHandRecorder.players) do
            if player.chairID == chairID then
                userID = player.userID
                break
            end
        end
    end

    if userID == nil then
        -- 根据chairID获取不到userID，说明输入的回放码不正确或已过期
        g_commonModule:ShowTip("您输入的回放码不存在,或录像已过期!")
        return
    else
        logger.debug(" tryEnterReplayRoom userID " .. userID)
    end
    -- self.locked = true

    -- GuanZhang/Script/

    local path = "GuanZhang.Script."

    local Replay = require(path .. "dfMahjong.dfReplay")

    if Replay == nil then
        logError("Replay == nil")
    end

    local rp = Replay:new(self, userID, msgHandRecorder)

    rp:gogogo(isShare)

    self.locked = false
end

-- 退出到登录界面
function DF:forceExit2LoginView()
    if self.room ~= nil then
        self.room:completedWait()
        self.room.isDestroy = true
        self.forceExit = true

        --如果此时等在等待websocket消息，
        --则唤醒coroutine，并让其执行退出DF流程
        self:triggerLeaveRoom()

        if self.ws ~= nil then
            local ws = self.ws
            self.ws = nil
            ws:disConnect()
        end
    end
end

function DF:logout(msg)
    logger.debug("dfsingleton logout")
    local config = {
        content = msg or "您已在其他地方登录，请重新登录！",
        ignoreCloseBtn = true,
        callback = function(...)
            dispatcher:dispatch("LOGOUT", arg)
            UnityEngine.PlayerPrefs.SetString("weiChat_openid", "")
            UnityEngine.PlayerPrefs.SetString("weiChat_token", "")
            local accModule = require("AccComponent.Script.AccModule")
            g_ModuleMgr:RemoveModule(accModule.moduleName)

            local loginModule = require("LoginComponent.Script.LoginModule")
            g_ModuleMgr:AddModule(loginModule.moduleName, loginModule)
            dispatcher:dispatch("OPEN_LOGINVIEW", {isLogout = true})
        end
    }
    g_commonModule:ShowDialog(config)
end

return DF
