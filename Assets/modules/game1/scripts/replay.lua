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

-- local fairy = require "lobby/lcore/fairygui"

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
    logger.debug("replay msgHandRecord:", self.msgHandRecord)
    for _, p in ipairs(players) do
        --if p.userID == acc.userID then
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

    self.exit = false
    self.actionStep = 0

    -- 启动定时器
    self.room.roomView.unityViewNode:StartTimer(
        "replay",
        self.speed,
        0,
        function()
            local msg = {mt = msgQueue.MsgType.replay}
            mq:pushMsg(msg)
        end
    )

    local msg = {mt = msgQueue.MsgType.replay}
    mq:pushMsg(msg)

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
--降低速度
---------------------------------
function Replay:decreaseSpeed()
    if self.speed >= (4 * self.normalSpeed) then
        prompt.showPrompt("已经是最慢速度")
        return
    end

    self.speed = self.speed * 2
    self:showCurrentSpeed()
end
---------------------------------
--增加速度
---------------------------------
function Replay:increaseSpeed()
    if self.speed <= (self.normalSpeed / 4) then
        prompt.showPrompt("已经是最快速度")
        return
    end

    self.speed = self.speed / 2
    self:showCurrentSpeed()
end
function Replay:showCurrentSpeed()
    local scale
    if self.speed <= self.normalSpeed then
        scale = self.normalSpeed / self.speed
        prompt.showPrompt("速度X" .. tostring(scale))
    else
        scale = self.speed / self.normalSpeed
        prompt.showPrompt("速度/" .. tostring(scale))
    end
end
---------------------------------
--退出房间
---------------------------------
function Replay:onExitReplay()
    self.exit = true
    --logError("on exit : "..tostring(self.coWait ~= nil))
    if self.coWait ~= nil then
        self:resumeCo()
    end
end
---------------------------------
--暂停后继续
---------------------------------
function Replay:onPauseResume()
    self.pause = false
    --隐藏继续按钮
    --显示暂停按钮
    self.room.roomView:pauseResumeButtons(true, false)
    if self.coWait ~= nil then
        self:resumeCo()
    end
end
---------------------------------
--暂停
---------------------------------
function Replay:onPause()
    self.pause = true

    --隐藏暂停按钮
    --显示继续按钮
    self.room.roomView:pauseResumeButtons(false, true)
end

---------------------------------
--等待继续或者退出房间
---------------------------------
function Replay:waitPauseResume()
    --隐藏暂停按钮
    --显示继续按钮
    self.room.roomView:pauseResumeButtons(false, true)

    local coWait = coroutine.running()

    self.coWait = coWait
    coroutine.yield()

    self.coWait = nil
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
    room:hideDiscardedTips()

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
