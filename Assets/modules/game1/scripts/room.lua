--[[
    Room保存着所有player
    players用chairId索引
]]
local Room = {}
Room.VERSION = "1.0"

local mt = {__index = Room}

local logger = require "lobby/lcore/logger"
local proto = require "scripts/proto/proto"
local rapidjson = require("rapidjson")
local RoomView = require("scripts/roomView")
local Player = require("scripts/player")

-----------------------------------------------------------
--初始化顶层消息响应handlers，有些消息例如ActionResultNotify
--就需要msg handler继续switch case消息体内的action码
-----------------------------------------------------------
local function initMsgHandler()
    local msgHandlers = {}
    local msgCodeEnum = proto.pokerface.MessageCode
    --服务器请求玩家进行动作，例如服务器请求玩家出牌
    --或者暗杠，加杠等等
    local h = require("scripts/handlers/handlerMsgActionAllowed")
    msgHandlers[msgCodeEnum.OPActionAllowed] = h

    --服务器请求对手玩家进行动作
    --例如吃椪杠等等
    h = require("scripts/handlers/handlerMsgReActionAllowed")
    msgHandlers[msgCodeEnum.OPReActionAllowed] = h

    --服务器通知玩家动作结果
    --该动作可能是本玩家发起的，也可能是其他玩家发起的
    h = require("scripts/handlers/handlerMsgActionResult")
    msgHandlers[msgCodeEnum.OPActionResultNotify] = h

    --服务器发牌
    h = require("scripts/handlers/handlerMsgDeal")
    msgHandlers[msgCodeEnum.OPDeal] = h

    --手牌结束时，服务器下发计分结果
    h = require("scripts/handlers/handlerMsgHandOver")
    msgHandlers[msgCodeEnum.OPHandOver] = h

    --房间更新（主要是玩家进入，或者离开之类）
    h = require("scripts/handlers/handlerMsgRoomUpdate")
    msgHandlers[msgCodeEnum.OPRoomUpdate] = h

    --掉线恢复
    h = require("scripts/handlers/handlerMsgRestore")
    msgHandlers[msgCodeEnum.OPRestore] = h

    --房间删除、解散
    h = require("scripts/handlers/handlerMsgDeleted")
    msgHandlers[msgCodeEnum.OPRoomDeleted] = h

    --显示提示信息
    h = require("scripts/handlers/handlerMsgShowTips")
    msgHandlers[msgCodeEnum.OPRoomShowTips] = h

    --牌局结束
    h = require("scripts/handlers/handlerMsgGameOver")
    msgHandlers[msgCodeEnum.OPGameOver] = h

    --牌局解散请求回复和通告
    h = require("scripts/handlers/handlerMsgDisbandNotify")
    msgHandlers[msgCodeEnum.OPDisbandNotify] = h

    --踢人结果通知
    h = require("scripts/handlers/handlerMsgKickoutResult")
    msgHandlers[msgCodeEnum.OPKickout] = h

    --道具通知
    h = require("scripts/handlers/handlerMsgDonate")
    msgHandlers[msgCodeEnum.OPDonate] = h

    --用户位置更新
    h = require("scripts/handlers/handlerMsgLocationUpdate")
    msgHandlers[msgCodeEnum.OPUpdateLocation] = h

    --用户返回大厅
    h = require("scripts/handlers/handlerMsgReturnHall")
    msgHandlers[msgCodeEnum.OP2Lobby] = h

    --更新道具配置
    h = require("scripts/handlers/handlerMsgPropCfgUpdate")
    msgHandlers[msgCodeEnum.OPUpdatePropCfg] = h
    return msgHandlers
end

--handlers属于整个Room
Room.Handlers = initMsgHandler()

-----------------------------------------------------------
--create a room object
--@param user user 对象，房间拥有者，通过user对象访问用户各种数据
-----------------------------------------------------------
function Room.new(user, dfReplay)
    local room = {user = user, dfReplay = dfReplay}
    --players初始化位空表，player使用chairId来索引
    room.players = {}
    --庄家座位id
    room.bankerChairID = 0

    return setmetatable(room, mt)
end

-------------------------------------------
-- 是否处于记录回播模式
-- 在此模式下，需要隐藏一些按钮，以及所有玩家都是明牌显示
-------------------------------------------
function Room:isReplayMode()
    return self.dfReplay ~= nil
end

-----------------------------------------------------------
--根据userId找到player对象
--@param userID 64位userid
-----------------------------------------------------------
function Room:getPlayerByUserId(userID)
    --logError("getPlayerByUserId : "..userID)
    for _, v in pairs(self.players) do
        if v:isMyUserId(userID) then
            return v
        end
    end
    return nil
end

-------------------------------------------
-- 根据chairID找到player对象
-------------------------------------------
function Room:getPlayerByChairID(chairID)
    for _, v in pairs(self.players) do
        if v.chairID == chairID then
            return v
        end
    end
    return nil
end

-------------------------------------------
-- 获得自身的player对象
-------------------------------------------
function Room:me()
    return self:getPlayerByUserId(self.user.userID)
end

-------------------------------------------
-- 判断player是否玩家自身
-------------------------------------------
function Room:isMe(player)
    return self.user.userID == player.userID
end

-------------------------------------------
-- 消息分发
-- 主要处理最外层的GameMessage消息结构
-------------------------------------------
function Room:dispatchWeboscketMessage(gmsg)
    self:dispatchGameMessage(gmsg)
end

-------------------------------------------
-- 分发GameMessage消息
-------------------------------------------
function Room:dispatchGameMessage(gmsg)
    local op = gmsg.Ops
    local handler = self.Handlers[op]
    if handler == nil then
        logger.debug(" Room:dispatchWeboscketMessage, no handler for:" .. op)
        return
    end

    local msgData = gmsg.Data
    logger.debug(" room dispatch msg, op:", gmsg.Ops, ",data size:", #msgData)
    -- 调用handler的onMsg
    handler.onMsg(msgData, self)
end

----------------------------------------------
-- 显示道具动画
----------------------------------------------
function Room:showDonate(msgDonate)
    if msgDonate then
        local itemID = msgDonate.itemID
        local propCfg = self:getPropCfg(itemID)
        if propCfg == nil then
            logger.debug("propCfg == nil ")
            return
        end
        itemID = propCfg["propID"]

        local oCurOpObj = self.roomView.donateMoveObj
        local obj = oCurOpObj:Find("Donate")

        local donate = tool:UguiAddChild(oCurOpObj, obj, obj.name)
        local image = donate:SubGet("Image", "Image")

        local fromPlayer = self:getPlayerByChairID(msgDonate.fromChairID)
        local toPlayer = self:getPlayerByChairID(msgDonate.toChairID)
        if fromPlayer == nil or toPlayer == nil then
            logger.debug(" fromPlayer or toPlayer is nil...")
            return
        end
        if msgDonate.toChairID == self.curActiveChairID then
            --更新界面信息  to的player 主要更新 红心数量
            toPlayer.playerView:updateHeadPopup()
            toPlayer.playerView:updatePropNum(msgDonate.itemID)
        end
        if msgDonate.fromChairID == self.curActiveChairID then
            --更新界面信息  from的player 主要更新 钻石数量
            fromPlayer.playerView:updateHeadPopup()
            fromPlayer.playerView:updatePropNum(msgDonate.itemID)
        end
        donate.localPosition = fromPlayer.playerView.infoGroup.localPosition
        local vTargetPos = toPlayer.playerView.infoGroup.localPosition
        image.transform:SetActive(true)
        donate:SetActive(true)
        local sprite = dfCompatibleAPI:loadCommonDynPic("prop/" .. itemID)
        local effobjSUB = itemID
        local sound = itemID
        if sprite == nil or effobjSUB == nil then
            logger.debug(" sprite or effobjSUB is nil...")
            return
        end
        image.sprite = sprite
        --飞动画
        self.roomView.unityViewNode:DelayRun(
            0.5,
            function()
                --oCurOpObj.transform 飞的图片
                self.roomView.unityViewNode:RunAction(
                    donate,
                    {
                        "localMoveTo",
                        vTargetPos.x,
                        vTargetPos.y,
                        1,
                        function()
                            --飞完之后的回调
                            --飞完之后 关闭oCurOpObj
                            image.transform:SetActive(false)
                            --播放特效
                            effobj =
                                Animator.Play(
                                "Component/CommonComponent/Bundle/prefab/prop/" .. effobjSUB .. ".prefab",
                                self.roomView.unityViewNode.order,
                                nil,
                                function()
                                    --动效完成后回调
                                    donate.gameObject:Destroy()
                                end
                            )
                            effobj.name = "sub"
                            effobj:SetParent(donate, false)
                            effobj.localPosition = Vector3(0, 0, 0)
                            --播放声音
                            if sound ~= nil then
                                dfCompatibleAPI:soundCommonPlay("prop/" .. sound)
                            end
                        end
                    }
                )
            end
        )
    end
end

----------------------------------------------
-- 加载房间的view
-- TODO:暂时用着LZOnlineView这个prefab
----------------------------------------------
function Room:loadRoomView()
    -- 当前的view（大厅view）替换为LZOnlineView
    -- ResourceManager:LoadFontAssetBundle("GameModule/GuanZhang/_AssetsBundleRes/Fonts/FZSXSLKJW.ttf")

    -- g_ModuleMgr:GetModule(ModuleName.DISPATCH_MODULE):register("LZOnlineViewInitFinish", self, self.InitRoomView)
    -- local starttime = os.clock()
    -- local roomCfg = {
    --     luaPath = "View/LZOnlineView",
    --     resPath = "GameModule/GuanZhang/_AssetsBundleRes/prefab/bund3/LZOnlineView.prefab"
    -- }
    -- local function cb(view)
    --     self.roomViewObj = view
    -- end
    self:initRoomView()
    -- g_ModuleMgr:GetModule(ModuleName.SCENE_MODULE):EnterScene("Room", roomCfg, cb)

    -- log(string.format("-----Room:loadRoomView--ReplaceView---cost time  : %.4f", os.clock() - starttime))
end

function Room:initRoomView()
    local starttime = os.clock()
    local roomView = RoomView.new(self)
    self.roomView = roomView
    self.initRoomViewFinish = true

    -- log(string.format("------Room:loadRoomView--InitRoomView---cost time  : %.4f", os.clock() - starttime))

    -- g_ModuleMgr:GetModule(ModuleName.DISPATCH_MODULE):unregister("LZOnlineViewInitFinish", self, self.InitRoomView)
end

----------------------------------------------
-- 加载一手牌结束后，显示结果的view
----------------------------------------------
function Room:loadHandResultView()
    local viewObj =
        viewModule:CreatePanel(
        {
            luaPath = "View/DFResultView",
            resPath = "GameModule/GuanZhang/_AssetsBundleRes/prefab/bund2/DFResultView.prefab",
            superClass = self.roomView.unityViewNode,
            parentNode = self.roomView.unityViewNode.transform
        }
    )
    local uiDepth = viewObj:GetComponent("UIDepth")
    if not uiDepth then
        uiDepth = viewObj:AddComponent(UIDepth)
    end
    uiDepth.canvasOrder = self.roomView.unityViewNode.order + 2
    if self:isReplayMode() then
        local handResultView = HandResultView:new(self, viewObj, waitCo)
        self.handResultView = handResultView
        return
    end

    --local handResultView = HandResultView:new(self, "LZResultView")
    --local waitCo = coroutine.running()
    local handResultView = HandResultView:new(self, viewObj, waitCo)
    self.handResultView = handResultView

    self:beginWait(pokerfaceProto.OPDisbandNotify)
    --coroutine.yield()
end

----------------------------------------------
-- 加载游戏结束后，显示结果的view
----------------------------------------------
function Room:loadGameOverResultView()
    local viewObj =
        viewModule:OpenMsgBox(
        {
            luaPath = "View/DFOverView",
            resPath = "GameModule/GuanZhang/_AssetsBundleRes/prefab/bund2/DFOverView.prefab"
        },
        self
    )
    local gameOverResultView = GameOverResultView:new(self, viewObj, waitCo)
    self.gameOverResultView = gameOverResultView
    --coroutine.yield()
    self:beginWait(pokerfaceProto.OPDisbandNotify)
end

----------------------------------------------
-- 创建玩家对象
-- 并绑定playerView
----------------------------------------------
function Room:createPlayerByInfo(playerInfo)
    --TODO: 和createMyPlayer一起抽取一个共同的函数用于new一个基本player
    local player = Player.new(playerInfo.userID, playerInfo.chairID, self)
    player.state = playerInfo.state
    player.nick = playerInfo.nick
    if player.nick == nil or player.nick == "" then
        player.nick = playerInfo.userID
    end

    player:updateByPlayerInfo(playerInfo)

    local playerView = self:getPlayerViewByChairID(playerInfo.chairID)
    player:bindView(playerView)

    self.players[player.userID] = player
end

----------------------------------------------
-- 创建自身的玩家对象
-- 并绑定playerView
----------------------------------------------
function Room:createMyPlayer(playerInfo)
    local player = Player.new(playerInfo.userID, playerInfo.chairID, self)
    player.state = playerInfo.state
    player.nick = playerInfo.nick
    if player.nick == nil or player.nick == "" then
        player.nick = playerInfo.userID
    end

    player:updateByPlayerInfo(playerInfo)

    local playerView = self.roomView.downPlayerView
    player:bindView(playerView)

    self.players[player.userID] = player

    self.myPlayer = player

    -- 隐藏空椅子
    --self.roomView:hideEmptyChair(player.chairID)
end

function Room:playerCount()
    local count = 0
    for _ in pairs(self.players) do
        count = count + 1
    end
    return count
end
----------------------------------------------
-- 根据玩家的chairID获得相应的playerView
-- 注意服务器的chairID是由0开始
----------------------------------------------
function Room:getPlayerViewByChairID(chairID)
    local playerViews = self.roomView.playerViews
    local myChairId = self.myPlayer.chairID

    --获得chairID相对于本玩家的偏移
    local c = (chairID - myChairId + 3) % 3
    --加1是由于lua table索引从1开始
    return playerViews[c + 1]
end
----------------------------------------------
-- 根据玩家的chairID获得相应的playerViewChairID
-- 注意服务器的chairID是由0开始
----------------------------------------------
function Room:getPlayerViewChairIDByChairID(chairID)
    local myChairId = self.myPlayer.chairID
    --获得chairID相对于本玩家的偏移
    local c = (chairID - myChairId + 3) % 3
    --加1是由于lua table索引从1开始
    return c + 1
end
----------------------------------------
--从房间的玩家列表中删除一个玩家
--注意玩家视图的解除绑定需要外部处理
----------------------------------------
function Room:removePlayer(player)
    self.players[player.userID] = nil
end

----------------------------------------
--往服务器发送action消息
----------------------------------------
function Room:sendActionMsg(msgAction)
    self:sendMsg(proto.pokerface.MessageCode.OPAction, msgAction)
end

----------------------------------------
--往服务器发送消息
----------------------------------------
function Room:sendMsg(opCode, msg)
    local host = self.host
    if host == nil then
        return
    end

    local ws = host.ws
    if ws == nil then
        return
    end
    -- local gmsg = pokerfaceProto.GameMessage()
    -- gmsg.Ops = opCode

    -- if msg ~= nil then
    --     gmsg.Data = msg:SerializeToString()
    -- end

    -- local pbData = gmsg:SerializeToString()
    -- ws:sendData(pbData)
    local gmsg = {}
    gmsg.Ops = opCode

    if msg ~= nil then
        gmsg.Data = msg
    end

    local buf = proto.encodeMessage("pokerface.GameMessage", gmsg)
    ws:sendBinary(buf)
end

--------------------------------------
--重置房间，以便开始新一手游戏
--------------------------------------
function Room:resetForNewHand()
    local players = self.players
    for _, p in pairs(players) do
        p:resetForNewHand()
    end
    --隐藏箭头
    -- self.roomView:setArrowHide()
end

------------------------------------
--把tilesInWall显示到房间的剩余牌数中
------------------------------------
function Room:updateTilesInWallUI()
    -- local str = "剩牌：%s"
    -- self.roomView.tilesInWall.text = string.format(str, tostring(self.tilesInWall))
end

------------------------------------
--主要是订阅一些聊天通知等
------------------------------------
function Room:initialize()
    notificationCenter:register(self, self.onChatMsg, Notifications.OnInPlayerChatMessage)
end

------------------------------------
--主要是取消订阅一些聊天通知等
------------------------------------
function Room:unInitialize()
    notificationCenter:unregister(self, Notifications.OnInPlayerChatMessage)

    self.roomView:unInitialize()

    self.emoji = nil

    -- --< 这部分可以去掉,因为有下面的CloseMessageBox
    -- if self.handResultView ~= nil then
    --     self.handResultView:destroy()
    -- end

    -- if self.gameOverResultView ~= nil then
    --     self.gameOverResultView:destroy()
    -- end -->
    -- --退出房间清除弹窗
    -- ViewManager.CloseMessageBox(true)
end

------------------------------------
--接收消息，显示到对应的player里面
------------------------------------
function Room:onChatMsg(msgChat)
    if not self.emoji then
        self.emoji = {}
    end

    --logError("onChatMsg ： " .. tostring(msgChat))
    --self.roomView:OnPlayerChat(msgChat)
    local scope = msgChat.scope
    local from = msgChat.from
    local to = msgChat.to
    local dataType = msgChat.dataType
    local player = self:getPlayerByUserId(from)
    local playerView = player.playerView
    --清理之前的消息框
    if playerView.textChatDelayRun ~= nil then
        self.roomView.unityViewNode:CancelDelayRun(playerView.textChatDelayRun)
    end
    if playerView.oCurTextChat ~= nil then
        playerView.oCurTextChat:Hide()
        playerView.oCurTextChat = nil
    end
    if dataType == accessory_pb.Voice then
        --VoiceChatUtl.RevClipData(msgChat.data);
        --self.roomView:OnPlayReceivedChatData(from,10)
        --语音消息处理
        --logError("msgChat.data ---------------- :" .. #msgChat.data)
    else
        local record = rapidjson.decode(msgChat.data)
        local chatMessage = record["msg"]

        local oCurTextChat = nil
        if dataType == accessory_pb.Text or dataType == accessory_pb.Buildin then
            oCurTextChat = playerView.head.textChat
            --一行限制在15个字符
            chatMessage = chatMessage or ""
            local showMsg = tool:StringInsert(chatMessage, "\n", 15)

            oCurTextChat:SubGet("msg", "Text").text = tostring(chatMessage)
            oCurTextChat:Show()
        elseif dataType == accessory_pb.Emoji then
            local data = rapidjson.decode(msgChat.data)
            local emojiName = data.msg
            oCurTextChat = playerView.head.faceChat

            g_ModuleMgr:GetModule(ModuleName.TOOLLIB_MODULE):DestroyAllChilds(oCurTextChat)
            if not self.emoji[emojiName] then
                --local emojiObj = resMgr.LoadAsset("LanZhouMaJiang/prefab/bund1/",emojiName)
                local emojiObj =
                    ResourceManager:LoadPrefab(
                    "GameModule/GuanZhang/_AssetsBundleRes/prefab/bund1/" .. emojiName .. ".prefab"
                )
                emojiObj:SetParent(self.roomView.unityViewNode.transform, false)
                emojiObj:Hide()
                if emojiObj then
                    self.emoji[emojiName] = emojiObj
                else
                    logError("加载表情失败 ： " .. tostring(emojiName))
                    return
                end
            end

            local prefab = self.emoji[emojiName]
            local obj = tool:UguiAddChild(oCurTextChat, prefab, "emoji")
            obj.transform.localPosition = Vector3(0, -40, 0)
            oCurTextChat:Show()
        end

        if dataType == accessory_pb.Buildin then
            local chatIndex = record["index"]
            local sSpeakSoundName = self:getChatCommonSpeakeRname(player.chairID, chatIndex)
            if sSpeakSoundName ~= "" then
                dfCompatibleAPI:soundPlay(sSpeakSoundName)
            end
        end --内置快捷消息的声音

        playerView.oCurTextChat = oCurTextChat
        playerView.textChatDelayRun =
            self.roomView.unityViewNode:DelayRun(
            dfConfig.ANITIME_DEFINE.CHATQIPAOSHOWTIME,
            function()
                oCurTextChat:Hide()
                oCurTextChat = nil
            end
        )
    end
end
------------------------------------
--获取语音文件
-----------------------------------
function Room:getChatCommonSpeakeRname(chairId, chatIndex)
    local sSpeakSoundName = ""
    local player = self:getPlayerByChairID(chairId)
    if player ~= nil and player.sex == 1 then
        sSpeakSoundName = "commonLanguage/boy/speak" .. chatIndex
    else
        sSpeakSoundName = "commonLanguage/girl/speak" .. chatIndex
    end
    return sSpeakSoundName
end
------------------------------------
--接收语音消息 user_dbid:用户id   voiceTime:语音时长
-----------------------------------
function Room:OnPlayReceivedVoiceData(user_dbid, voiceTime)
    --if not UserData.voiceCfg.chatIsOn then return end 	--聊天未开放 不显示语音气泡
    --logError("test Room OnPlayReceivedVoiceData")
    local delayRunMap = self.roomView.delayRunMap
    delayRunMap[user_dbid] = delayRunMap[user_dbid] or {}
    local receivedClickDelay = delayRunMap[user_dbid].receivedClickDelay
    local receivedDelay = delayRunMap[user_dbid].receivedDelay
    self.roomView.unityViewNode:CancelDelayRun(receivedClickDelay)
    self.roomView.unityViewNode:CancelDelayRun(receivedDelay)
    soundMgr:SetBackMusicVolume(0)
    local player = self:getPlayerByUserId(tostring(user_dbid))
    if player ~= nil then
        local playerView = player.playerView
        local chairID = playerView.viewChairID
        playerView.head.playerVoiceNode:SetActive(true)
        playerView.head.playerVoiceTextNode.text = tostring(voiceTime)
        self:showPlayerVoiceAnimation(player)
        receivedDelay =
            self.roomView.unityViewNode:DelayRun(
            voiceTime,
            function()
                self.roomView.unityViewNode:CancelDelayRun(receivedDelay)
                self:stopPlayerVoiceAnimation(player)
                self:resumeBackMusicVolume()
            end
        )
        delayRunMap[user_dbid].receivedDelay = receivedDelay
    -- self.unityViewNode:AddClick(self.ViewNodes.playerVoiceNodes[chairID], function()
    -- 	self.unityViewNode:CancelDelayRun(receivedDelay)
    -- 	self.unityViewNode:CancelDelayRun(receivedClickDelay)
    -- 	soundMgr:SetBackMusicVolume(0);
    -- 	self:stopPlayerVoiceAnimation(player);
    -- 	local seconds = VoiceChatUtl.PlayLastVoiceClip(user_dbid)
    --     logError("seconds: "..tostring(seconds))
    -- 	self:showPlayerVoiceAnimation(player);
    -- 	receivedClickDelay = self.unityViewNode:DelayRun(seconds, function()
    -- 		self.unityViewNode:CancelDelayRun(receivedClickDelay)
    -- 		self:stopPlayerVoiceAnimation(player);
    -- 		self:resumeBackMusicVolume()
    -- 	end)
    -- 	self.delayRunMap[user_dbid].receivedClickDelay = receivedClickDelay
    -- end)
    end
end

--背景声音
function Room:resumeBackMusicVolume(backMusicVolume)
    --if self:DelayRunCanceled() then
    -- if backMusicVolume then
    --     soundMgr:SetBackMusicVolume(backMusicVolume)
    -- else
    --     soundMgr:SetBackMusicVolume(soundModule.backMusicVolume)
    -- end
    --end
end

-- function RoomView:DelayRunCanceled()
-- 	local canceled = true
-- 	for k,v in pairs(self.delayRunMap) do
-- 		if not self:IsDelayCanceled(v.receivedDelay) or not self:IsDelayCanceled(v.receivedClickDelay) then
-- 			canceled = false
-- 			break
-- 		end
-- 	end
-- 	if not self:IsDelayCanceled(self.selfVoiceClickDelay) or not self:IsDelayCanceled(self.upDelayRun) then
-- 		canceled = false
-- 	end
-- 	return canceled
-- end
-- function RoomView:IsDelayCanceled(co)
-- 	if co == nil then return true end
-- 	return self._cos[co] == nil
-- end
--播放声音波动动画
function Room:runRecordValueAnimation(actionList, node, index, count)
    local duration = 0.5
    node:SetActive(false)
    if actionList[index] then
        actionList[index]:Kill(false)
    end

    actionList[index] =
        self.roomView.unityViewNode:RunAction(
        node,
        {
            {
                "delay",
                duration * index,
                function()
                    node:SetActive(true)
                end
            },
            {
                "delay",
                duration * (count + 1 - index),
                function()
                    self:runRecordValueAnimation(actionList, node, index, count)
                end
            }
        }
    )
end

function Room:stopPlayerVoiceAnimation(player)
    if player.playerView.head.playerVoiceAction and player.playerView.head.playerVoiceAction then
        for index, action in ipairs(player.playerView.head.playerVoiceAction) do
            action:Kill(false)
            player.playerView.head.playerVoiceNode:SetActive(false)
        end
    end

    local voiceNode = player.playerView.head.playerVoiceNode
    local count = 3
    for index = 1, count do
        voiceNode:Find("AnimateLayer/Voice" .. index):SetActive(true)
    end
end

function Room:showPlayerVoiceAnimation(player)
    self:stopPlayerVoiceAnimation(player)

    player.playerView.head.playerVoiceAction = {}

    local voiceNode = player.playerView.head.playerVoiceNode
    voiceNode:SetActive(true)
    local count = 3
    for index = 1, count do
        local node = voiceNode:Find("AnimateLayer/Voice" .. index)
        self:runRecordValueAnimation(player.playerView.head.playerVoiceAction, node, index, count)
    end
end

function Room:destroyRoomView()
    if self.roomView ~= nil then
        self.roomView:destroyRoomView()
        self.roomView = nil
    end
    --如果解散窗口存在则删除
    if self.disbandVoteView ~= nil then
        --注销解散框的销毁， 不然点解散房间，然后断网重新连网，导致view不存在报错
        -- self.disbandVoteView:destroy()
        self.disbandVoteView = nil
    end
end

-----------------------------------------------------------
--执行自动打牌操作
-----------------------------------------------------------
function Room:stopDiscardCountdown()
    -- self.roomView.unityViewNode:StopTimer("timer_djs")
    -- self.roomView.countdown:SetActive(false)
    --self.roomView.CountDownText.text = ""
end

-----------------------------------------------------------
--开始打牌倒计时
-----------------------------------------------------------
function Room:startDiscardCountdown(player)
    --重置定时器
    -- self.roomView.unityViewNode:StopTimer("timer_djs")

    local nGetRoomCountDown = 0
    --if countDown then nGetRoomCountDown = countDown end
    local djsCnt = 1
    -- self.roomView.countdownText.text = tostring(djsCnt)
    -- self.roomView.countdown:SetActive(true)
    -- self.roomView.countdown.transform.localPosition = player.playerView.countdownPos.transform.localPosition

    -- self.roomView.unityViewNode:StartTimer(
    --     "timer_djs",
    --     1,
    --     function()
    --         djsCnt = djsCnt + 1
    --         if djsCnt > 9 then
    --             self.roomView.countdownText.text = tostring(djsCnt)
    --         else
    --             self.roomView.countdownText.text = "0" .. djsCnt
    --         end
    --         if djsCnt > 998 then
    --             self.roomView.unityViewNode:StopTimer("timer_djs")
    --         end
    --         if djsCnt == 3 then
    --         --来个抖动效果
    --         end
    --     end,
    --     0
    -- )
end

---------------------------------------
--处理玩家申请解散请求
---------------------------------------
function Room:onDissolveClicked()
    if self.disbandLocked and self.msgDisbandNotify ~= nil then
        --上次发送的，或者现在已经有了解散请求正在处理
        -- if self.msgDisbandNotify == nil then
        --     --如果上次发的包还没收到回复，则特殊处理 (2017-10-24 mufan)
        --     --点击解散房间，出现（放开那少年） 挂
        --     return
        -- end
        self:updateDisbandVoteView(self.msgDisbandNotify)
    else
        self:sendMsg(pokerfaceProto.OPDisbandRequest)
        self.disbandLocked = true
    end
end

--处理玩家返回大厅请求
---------------------------------------
function Room:onRetunHallClicked()
    self:sendMsg(pokerfaceProto.OP2Lobby)
end

---------------------------------------
--更新解散处理界面
---------------------------------------
function Room:updateDisbandVoteView(msgDisbandNotify)
    self.msgDisbandNotify = msgDisbandNotify

    if self.disbandVoteView then
        self.disbandVoteView:updateView(msgDisbandNotify)
    else
        local viewObj =
            viewModule:OpenMsgBox(
            {
                luaPath = "View/DissolveVoteView",
                resPath = "GameModule/GuanZhang/_AssetsBundleRes/prefab/bund2/DissolveVoteView.prefab"
            }
        )
        local disbandVoteView = require("scripts/handlers/disbandVoteView")
        self.disbandVoteView = disbandVoteView:new(self, viewObj)
        self.disbandVoteView:updateView(msgDisbandNotify)
    end
end

---------------------------------------
--关闭解散处理界面
---------------------------------------
function Room:destroyVoteView()
    if self.disbandVoteView then
        self.disbandVoteView:destroy()
        self.disbandVoteView = nil
    end
end

function Room:hideDiscardedTips()
    for _, p in pairs(self.players) do
        p:hideDiscardedTips()
    end
end
---------------------------------------
--发送解散回复给服务器
---------------------------------------
function Room:sendDisbandAgree(agree)
    local msgDisbandAnswer = pkproto2.MsgDisbandAnswer()
    msgDisbandAnswer.agree = agree

    self:sendMsg(pokerfaceProto.OPDisbandAnswer, msgDisbandAnswer)
end

function Room:getRoomConfig()
    if self.config ~= nil then
        return self.config
    end

    local roomInfo = self.roomInfo
    if roomInfo ~= nil and roomInfo.config ~= nil and roomInfo.config ~= "" then
        local config = rapidjson.decode(roomInfo.config)
        self.config = config
    end
    return self.config
end

----------------------------------------------------------
--获取房间规则（用于两个结算界面，空格有两个）
----------------------------------------------------------
function Room:getRule()
    local rule = ""
    local config = self:getRoomConfig()
    if config ~= nil then
        if config.playerNumAcquired ~= nil then
            rule = rule .. tostring(config.playerNumAcquired) .. "人场"
        end
        if config.handNum ~= nil then
            rule = "  " .. rule .. tostring(config.handNum) .. "局"
            self.handNum = config.handNum
        end
        if config.fengDingType ~= nil then
            local s = "  封顶100/200/300"
            if config.fengDingType == 0 then
                s = "  封顶20/40"
            elseif config.fengDingType == 1 then
                s = "  封顶30/60"
            elseif config.fengDingType == 2 then
                s = "  封顶50/100/150"
            end
            rule = rule .. " " .. s
        end
        if config.dunziPointType ~= nil then
            local s = "  墩子1/2"
            if config.dunziPointType == 1 then
                s = "  墩子2/4"
            elseif config.dunziPointType == 2 then
                s = "  墩子5/10/15"
            elseif config.dunziPointType == 3 then
                s = "  墩子10/20/30"
            end
            rule = rule .. " " .. s
        end
        if config.payType ~= nil then
            local s = "  房主支付"
            if config.payType == 1 then
                s = "  钻石平摊"
            end
            rule = rule .. s
        end
        if config.doubleScoreWhenSelfDrawn ~= nil and config.doubleScoreWhenSelfDrawn then
            rule = rule .. "  自摸加双"
        end
        if config.doubleScoreWhenContinuousBanker ~= nil and config.doubleScoreWhenContinuousBanker then
            rule = rule .. " 连庄"
        end
        if config.doubleScoreWhenZuoYuanZi ~= nil and config.doubleScoreWhenZuoYuanZi then
            rule = rule .. " 坐园子"
        end
    end
    return rule
end

----------------------------------------------------------
--获取GPS数据
----------------------------------------------------------
-- local indexes = {
-- [1] = {1, 2},
-- [2] = {1, 3},
-- [3] = {1, 4},
-- [4] = {2, 3},
-- [5] = {2, 4},
-- [6] = {3, 4}}
--loc:{"address":
--    {"city":"阿拉善盟","province":"内蒙古自治区","adcode":"152921","district":"阿拉善左旗","street":"",
--           "country_code":0,"town":"","direction":"","distance":"","street_number":"","country":"中国"},
--    "lat":39.007715452216,
--    "formatAddress":"内蒙古自治区阿拉善盟阿拉善左旗",
--    "IsGPS":true,"lng":105.574113517}
-- 解析GPS地址, 安全距离的情况下只显示到 district （保护玩家隐私）
function Room:getDistance(locations, ips)
    --用于记录player距离安不安全
    local safeLocations = {
        [1] = true,
        [2] = true,
        [3] = true
    }
    --安全距离
    local safeDistance = 20
    -- -1 空 ， 0 安全 ，1 距离20 ，2 ip相同 ，3 ip与距离
    local distance = {}
    local index = 1
    for i = 1, 3 do
        for j = i + 1, 3 do
            local x = locations[i]
            local y = locations[j]
            local ip1 = ips[i]
            local ip2 = ips[j]
            distance[index] = 0
            --如果 ip相同 或者 距离小于20   则红线
            --如果 ip不同 且 距离大于20     则绿线
            --如果 ip为空，                 则不连线 （显示灰色gps图标，提示，暂无用户）
            --如果 ip不为空，（显示黄色gps图标 ，如果location 为空 提示 未开启GPS）
            if ip1 == nil or ip2 == nil then
                distance[index] = -1
            else
                if x.IsGPS and y.IsGPS then
                    --logError("test distance = "..i..", "..j..", " ..dt)
                    --local dt = BaiduMapWeb.CalDistance(x.lng, x.lat, y.lng, y.lat)
                    local dt = Native.CalculateLineDistance(x.lat, x.lng, y.lat, y.lng)
                    local isSafe = dt >= safeDistance
                    distance[index] = 1
                    if isSafe then
                        distance[index] = 0
                    end
                    --distance[index] = distance[index] + disType
                    --当保存的距离为false的时候，就不再改变
                    if safeLocations[i] then
                        safeLocations[i] = isSafe
                    end
                    if safeLocations[j] then
                        safeLocations[j] = isSafe
                    end
                else
                    --距离如果安全的话，就不考虑Ip
                    if ip1 == ip2 then
                        safeLocations[i] = false
                        safeLocations[j] = false
                        distance[index] = distance[index] + 2
                    end
                end
            end
            index = index + 1
        end
    end
    self.safeLocations = safeLocations
    return distance
end
--大丰自己的弹框
function Room:openMessageBoxFromDaFengNoOrder(viewName, ...)
    return self:openMessageBoxFromDaFeng(viewName, nil, ...)
end

function Room:openMessageBoxFromDaFeng(viewName, order, ...)
    local viewObj =
        viewModule:CreatePanel(
        {
            luaPath = "View." .. viewName,
            resPath = "GameModule/GuanZhang/_AssetsBundleRes/prefab/bund2/" .. viewName .. ".prefab",
            parentNode = self.roomView.unityViewNode.transform
        },
        ...
    )
    return viewObj
end

function Room:ShowMessageBoxFromDaFeng(str, order, okFunc, noFunc)
    return dfCompatibleAPI:openDialog(str, okFunc, noFunc)
end

function Room:UIAction(target)
    local gameObject = target.transform.gameObject
    target.transform = gameObject.transform
    target.transform.size = Vector2(3000, 3000)
    target.transform:SetParent(self.roomView.unityViewNode.transform, false)
end

function Room:updatePlayerLocation(msgUpdateLocation)
    logger.debug("Room:updatePlayerLocation")
    local userID = msgUpdateLocation.userID
    local player = self.players[userID]
    if not player then
        logger.debug(" updatePlayerLocation, can't find player " .. userID)
        return
    end
    player.location = msgUpdateLocation.location

    if self.roomView == nil then
        return
    end

    local roomView = self.roomView
    if roomView.distanceView == nil then
        return
    end

    -- local distanceView = roomView.distanceView
    -- if distanceView.activeSelf then
    --     self.roomView:updateDistance()
    -- end
end

function Room:getPropCfg(index)
    local roomInfo = self.roomInfo
    local propCfgString = roomInfo.propCfg
    if propCfgString == nil or propCfgString == "" then
        logger.debug("room propCfg = nil")
        return nil
    end

    local propCfg = rapidjson.decode(propCfgString)
    if propCfg == nil then
        return nil
    end

    -- dump(propCfg, "-------propCfg--------")
    -- logger.debug("index:", index)

    return propCfg[tostring(index)]
end

-------------------------------------------------
---- 道具名称映射，根据道具配置获取对应的道具名称
------------------------------------------------
function Room:getPropIconName(prop)
    -- 预定义好道具名称与道具ID映射
    local propIncos = {
        ["1002"] = "dj_meigui",
        ["1003"] = "dj_ganbei",
        ["1004"] = "dj_jd",
        ["1005"] = "dj_tuoxie",
        ["1009"] = "dj_qj",
        ["1008"] = "dj_bb",
        ["1007"] = "dj_hj",
        ["1006"] = "dj_mmd"
    }

    if prop == nil then
        return ""
    end

    local propID = prop["propID"]
    local propIconName = propIncos[tostring(propID)]
    if propIconName == nil then
        return ""
    end

    return propIconName
end

function Room:updatePropCfg(msgUpdatePropCfg)
    logger.debug(" updatePropCfg:" .. msgUpdatePropCfg.propCfg)

    local roomInfo = self.roomInfo
    if roomInfo == nil then
        return
    end

    roomInfo.propCfg = msgUpdatePropCfg.propCfg
    self.roomView:refreshProps()
end

return Room
