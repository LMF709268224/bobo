--[[
    控制回播
]]
--luacheck: no self
local Replay = {}

local mt = {__index = Replay}
local logger = require "lobby/lcore/logger"
local prompt = require "lobby/lcore/prompt"
local proto = require "scripts/proto/proto"
local actionType = proto.prunfast.ActionType
local pokerface = proto.pokerface
local msgQueue = require "scripts/msgQueue"
local fairy = require "lobby/lcore/fairygui"

function Replay.new(singleton, msgHandRecord)
    local replay = {}

    replay.singleton = singleton
    replay.msgHandRecord = msgHandRecord
    replay.user = singleton.user

    return setmetatable(replay, mt)
end

local function clonePlayerInfo(p)
    local pi = {}
    pi.userID = p.userID
    pi.chairID = p.chairID
    pi.nick = p.nick
    pi.sex = p.sex
    pi.headIconURI = p.headIconURI
    pi.avatarID = p.avatarID

    return pi
end

function Replay:gogogo()
    local room = self.singleton.room
    self.room = room

    --新建player以及绑定playerView
    --先新建自己
    local players = self.msgHandRecord.players
    --logger.debug("replay msgHandRecord:", self.msgHandRecord)
    for _, p in ipairs(players) do
        logger.debug(" p.userID ", p.userID)
        if p.userID == self.user.userID then
            room:createMyPlayer(clonePlayerInfo(p))
        end
    end
    --新建其他人
    for _, p in ipairs(players) do
        --if p.userID ~= acc.userID then
        if p.userID ~= self.user.userID then
            room:createPlayerByInfo(clonePlayerInfo(p))
        end
    end

    --挂载action处理handler，复用action result handlers
    self:armActionHandler()
    self.speed = 0.5 -- 默认速度,每2秒一次
    self.normalSpeed = self.speed

    local mq = msgQueue.new()
    self.mq = mq

    self.actionStep = 0

    -- 启动定时器
    self:startStepTimer()

    local msg = {mt = msgQueue.MsgType.replay}
    mq:pushMsg(msg)

    -- 显示操作面板
    -- 去除模式对话框背景色（40%透明），设置为100%透明
    self.modalLayerColor = fairy.GRoot.inst.modalLayer.color
    local color = _ENV.CS.UnityEngine.Color(0, 0, 0, 0)
    fairy.GRoot.inst.modalLayer.color = color

    _ENV.thisMod:AddUIPackage("lobby/fui_replay/lobby_replay")
    local view = _ENV.thisMod:CreateUIObject("lobby_replay", "operations")
    local win = fairy.Window()
    win.contentPane = view
    win.modal = true

    self.win = win
    self:initView(view)
    win:Show()

    while true do
        msg = self.mq:getMsg()
        if msg.mt == msgQueue.MsgType.quit then
            -- quit
            break
        end

        if msg.mt == msgQueue.MsgType.replay then
            self:doReplayStep()
        end
    end

    -- 还原模式对话框背景色（40%透明）
    fairy.GRoot.inst.modalLayer.color = self.modalLayerColor
end

function Replay:startStepTimer()
    local mq = self.mq
    self.room.roomView.unityViewNode:StartTimer(
        "replay",
        self.speed,
        0,
        function()
            local msg = {mt = msgQueue.MsgType.replay}
            mq:pushMsg(msg)
        end
    )
end

function Replay:initView(view)
    local btnResume = view:GetChild("resume")
    local btnPause = view:GetChild("pause")
    local btnFast = view:GetChild("fast")
    local btnSlow = view:GetChild("slow")
    local btnBack = view:GetChild("back")

    btnResume.visible = false

    local s = self
    btnBack.onClick:Set(
        function()
            local msg = {mt = msgQueue.MsgType.quit}
            s.mq:pushMsg(msg)
        end
    )

    btnPause.onClick:Set(
        function()
            btnPause.visible = false
            btnResume.visible = true
            s.room.roomView.unityViewNode:StopTimer("replay")
        end
    )

    btnResume.onClick:Set(
        function()
            btnPause.visible = true
            btnResume.visible = false
            s:startStepTimer()

            local msg = {mt = msgQueue.MsgType.replay}
            s.mq:pushMsg(msg)
        end
    )

    btnFast.onClick:Set(
        function()
            if s.speed < 0.2 then
                logger.debug("fastest speed already")
                prompt.showPrompt("已经是最快速度")
                return
            end

            s.room.roomView.unityViewNode:StopTimer("replay")
            s.speed = s.speed / 2
            s:startStepTimer()
        end
    )

    btnSlow.onClick:Set(
        function()
            if s.speed > 3 then
                logger.debug("slowest speed already")
                prompt.showPrompt("已经是最慢速度")
                return
            end

            s.room.roomView.unityViewNode:StopTimer("replay")
            s.speed = s.speed * 2
            s:startStepTimer()
        end
    )
end

function Replay:doReplayStep()
    if self.actionStep == 0 then
        logger.debug("Replay:doReplayStep, deal")
        --重置房间
        self.room:resetForNewHand()
        --发牌
        self:deal()
    else
        local actionlist = self.msgHandRecord.actions
        if self.actionStep >= #actionlist then
            -- 已经播放完成了
            self.room.roomView.unityViewNode:StopTimer("replay")

            -- 结算页面
            self:handOver()
            self.win:BringToFront()
        else
            local a = actionlist[self.actionStep]
            if (a.flags & pokerface.SRFlags.SRUserReplyOnly) == 0 then
                self:doAction(a, actionlist)
            end
        end
    end

    self.actionStep = self.actionStep + 1
end

---------------------------------
--发牌
---------------------------------
function Replay:deal()
    local room = self.room
    --房间状态改为playing
    room.state = pokerface.RoomState.SRoomPlaying
    room.roomView:onUpdateStatus(room.state)

    local deals = self.msgHandRecord.deals
    --保存一些房间属性
    room.bankerChairID = self.msgHandRecord.bankerChairID
    local player1 = nil
    local player2 = nil
    local mySelf = nil
    --所有玩家状态改为playing
    local players = room.players
    for _, p in pairs(players) do
        p.state = pokerface.PlayerState.PSPlaying
        local onUpdate = p.playerView.onUpdateStatus[p.state]
        onUpdate(room.state)
        if p:isMe() then
            mySelf = p
        else
            if player1 == nil then
                player1 = p
            else
                player2 = p
            end
        end
    end

    local drawCount = 0
    --保存每一个玩家的牌列表
    for _, v in ipairs(deals) do
        local chairID = v.chairID
        local player = room:getPlayerByChairID(chairID)
        drawCount = drawCount + #v.cardsHand
        player.cardsOnHand = {}
        --填充手牌列表，所有人的手牌列表
        player:addHandTiles(v.cardsHand)
    end

    --显示各个玩家的手牌（对手只显示暗牌）和花牌
    for _, p in pairs(players) do
        p:sortHands()
        p:hand2UI(false, false)
    end

    --播放发牌动画，并使用coroutine等待动画完成
    room.roomView:dealAnimation(mySelf, player1, player2)

    --等待庄家出牌
    local bankerPlayer = room:getPlayerByChairID(room.bankerChairID)
    room.roomView:setWaitingPlayer(bankerPlayer)
end

---------------------------------
--执行动作
---------------------------------
function Replay:doAction(srAction, actionlist)
    local room = self.room
    local i = self.actionStep

    local player = room:getPlayerByChairID(srAction.chairID)
    room.roomView:setWaitingPlayer(player)

    local h = self.actionHandler[srAction.action]
    if h == nil then
        logger.error("Replay, no action handler:" .. tostring(srAction.action))
        return
    end
    if srAction.action == actionType.enumActionType_DISCARD then
        local waitDiscardReAction = false
        if i < #actionlist then
            waitDiscardReAction = true
        end
        h(self, srAction, room, waitDiscardReAction)
    else
        h(self, srAction, room)
    end
end

---------------------------------
--动作处理handlers
---------------------------------
function Replay:armActionHandler()
    local handers = {}

    handers[actionType.enumActionType_SKIP] = self.skipActionHandler
    handers[actionType.enumActionType_DISCARD] = self.discardedActionHandler

    self.actionHandler = handers
end
---------------------------------
--过
---------------------------------
function Replay:skipActionHandler(srAction, room)
    logger.debug(" replay, firstReadyHand")

    local actionResultMsg = {targetChairID = srAction.chairID}
    local h = require("scripts/handlers/handlerActionResultSkip")
    h.onMsg(actionResultMsg, room)
end

--深度复制table
local function clone(obj)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local newObject = {}
        lookup_table[object] = newObject
        for key, value in pairs(object) do
            newObject[_copy(key)] = _copy(value)
        end
        return setmetatable(newObject, getmetatable(object))
    end
    return _copy(obj)
end
---------------------------------
--出牌
---------------------------------
function Replay:discardedActionHandler(srAction, room, waitDiscardReAction)
    logger.debug(" replay, discarded")
    --这里要复制table出来用，否则，用户观看完一次回播记录之后，点击重播，srAction.cards会少了第一个元素
    local tiles = clone(srAction.cards)
    local cardHandType = tiles[1]
    table.remove(tiles, 1)
    local actionResultMsg = {
        targetChairID = srAction.chairID,
        actionHand = {cards = tiles, cardHandType = cardHandType},
        waitDiscardReAction = waitDiscardReAction
    }

    local h = require("scripts/handlers/handlerActionResultDiscarded")
    h.onMsg(actionResultMsg, room)
end
---------------------------------
--一手牌结束，显示得分页面
---------------------------------
function Replay:handOver()
    local room = self.room
    --TODO:关闭倒计时
    --room:stopDiscardCountdown()

    local handScoreBytes = self.msgHandRecord.handScore

    local msgHandOver = {continueAble = false}
    if handScoreBytes == nil or #handScoreBytes < 1 then
        msgHandOver.endType = pokerface.HandOverType.enumHandOverType_None
    else
        local handScore = proto.decodeMessage("pokerface.MsgHandScore", handScoreBytes)

        local endType
        for _, s in ipairs(handScore.playerScores) do
            endType = s.winType
        end

        msgHandOver.endType = endType
        msgHandOver.scores = handScore
    end

    room.msgHandOver = msgHandOver
    local players = room.players
    for _, p in pairs(players) do
        p.lastTile = p.cardsOnHand[#p.cardsOnHand] --保存最后一张牌，可能是胡牌。。。用于最后结算显示
    end

    local h = require "scripts/handlers/handlerMsgHandOver"
    h.onHandOver(msgHandOver, room)
end

return Replay
