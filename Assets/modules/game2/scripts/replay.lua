--[[
    控制回播
]]
--luacheck: no self
local Replay = {}

local mt = {__index = Replay}
local logger = require "lobby/lcore/logger"
local prompt = require "lobby/lcore/prompt"
local proto = require "scripts/proto/proto"
local actionType = proto.mahjong.ActionType
local mahjong = proto.mahjong
local msgQueue = require "scripts/msgQueue"
local fairy = require "lobby/lcore/fairygui"
local meldType = proto.mahjong.MeldType

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
            if (a.flags & mahjong.SRFlags.SRUserReplyOnly) == 0 then
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
    room.state = mahjong.RoomState.SRoomPlaying
    room.roomView:onUpdateStatus(room.state)

    local deals = self.msgHandRecord.deals
    --保存一些房间属性
    room.bankerChairID = self.msgHandRecord.bankerChairID
    --是否连庄
    room.isContinuousBanker = self.msgHandRecord.isContinuousBanker
    room.windFlowerID = self.msgHandRecord.windFlowerID

    --所有玩家状态改为playing
    local players = room.players
    for _, p in pairs(players) do
        p.state = mahjong.PlayerState.PSPlaying
        local onUpdate = p.playerView.onUpdateStatus[p.state]
        onUpdate(room.state)
    end

    --根据风圈修改
    room.roomView:setRoundMask(1)
    --修改庄家标志
    room:setBankerFlag()

    local drawCount = 0
    --保存每一个玩家的牌列表
    for _, v in ipairs(deals) do
        local chairID = v.chairID
        local player = room:getPlayerByChairID(chairID)
        drawCount = drawCount + #v.tilesHand
        player.tilesHand = {}
        --填充手牌列表，所有人的手牌列表
        player:addHandTiles(v.tilesHand)
        --填充花牌列表
        player:addFlowerTiles(v.tilesFlower)
    end

    --显示各个玩家的手牌（对手只显示暗牌）和花牌
    for _, p in pairs(players) do
        p:sortHands()
        p:hand2UI(false, false)
        p:flower2UI()
    end

    room.tilesInWall = 144 - drawCount
    room:updateTilesInWallUI()
    --播放发牌动画，并使用coroutine等待动画完成
    -- room.roomView:dealAnimation(mySelf, player1, player2)

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

    handers[actionType.enumActionType_FirstReadyHand] = self.firstReadyHandActionHandler
    handers[actionType.enumActionType_DISCARD] = self.discardedActionHandler
    handers[actionType.enumActionType_DRAW] = self.drawActionHandler
    handers[actionType.enumActionType_CHOW] = self.chowActionHandler
    handers[actionType.enumActionType_PONG] = self.pongActionHandler
    handers[actionType.enumActionType_KONG_Exposed] = self.kongExposedActionHandler
    handers[actionType.enumActionType_KONG_Concealed] = self.kongConcealedActionHandler
    handers[actionType.enumActionType_KONG_Triplet2] = self.triplet2KongActionHandler
    handers[actionType.enumActionType_WIN_Chuck] = self.winChuckActionHandler
    handers[actionType.enumActionType_WIN_SelfDrawn] = self.winSelfDrawActionHandler

    self.actionHandler = handers
end

---------------------------------
--起手听
---------------------------------
function Replay:firstReadyHandActionHandler(srAction, room)
    print("llwant, dfreplay, firstReadyHand")

    local actionResultMsg = {targetChairID = srAction.chairID}
    local h = require("scripts/handlers/handlerActionResultReadyHand")
    h.onMsg(actionResultMsg, room)
end
---------------------------------
--出牌
--补充庄家起手听
---------------------------------
function Replay:discardedActionHandler(srAction, room, waitDiscardReAction)
    print("llwant, dfreplay, discarded")
    local tiles = srAction.tiles
    local discardTileId = tiles[1]
    local actionResultMsg = {
        targetChairID = srAction.chairID,
        actionTile = tiles[1],
        waitDiscardReAction = waitDiscardReAction
    }
    local h = require("scripts/handlers/handlerActionResultDiscarded")
    h.onMsg(actionResultMsg, room)

    self.latestDiscardedPlayer = room:getPlayerByChairID(srAction.chairID)
    self.latestDiscardedTile = discardTileId

    if proto.actionsHasAction(srAction.flags, mahjong.SRFlags.SRRichi) then
        self:firstReadyHandActionHandler(srAction, room)
    end
end
---------------------------------
--抽牌
---------------------------------
function Replay:drawActionHandler(srAction, room)
    print("llwant, dfreplay, draw")
    local tiles = srAction.tiles
    local tilesFlower = nil
    if #tiles > 1 then
        tilesFlower = {}
        for i = 1, #tiles - 1 do
            tilesFlower[i] = tiles[i]
        end
    end

    local drawTile = tiles[#tiles]
    local drawCnt = #tiles
    if drawTile == 1 + mahjong.TileID.enumTid_MAX then
        drawCnt = drawCnt - 1
    end
    local tilesInWall = room.tilesInWall - drawCnt
    local actionResultMsg = {
        targetChairID = srAction.chairID,
        actionTile = drawTile,
        newFlowers = tilesFlower,
        tilesInWall = tilesInWall
    }

    local player = room:getPlayerByChairID(srAction.chairID)
    room.roomView:setWaitingPlayer(player)
    --player.lastTile = drawTile

    local h = require "scripts/handlers/handlerActionResultDraw"
    h.onMsg(actionResultMsg, room)
end
---------------------------------
--吃
---------------------------------
function Replay:chowActionHandler(srAction, room)
    print("llwant, dfreplay, chow")

    local tiles = srAction.tiles
    local actionMeld = {
        tile1 = tiles[1],
        chowTile = tiles[2],
        meldType = meldType.enumMeldTypeSequence,
        contributor = self.latestDiscardedPlayer.chairID
    }

    local chowTileId = tiles[2]

    local actionResultMsg = {targetChairID = srAction.chairID, actionMeld = actionMeld, actionTile = chowTileId}
    local h = require "scripts/handlers/handlerActionResultChow"
    h.onMsg(actionResultMsg, room)
end
---------------------------------
--碰
---------------------------------
function Replay:pongActionHandler(srAction, room)
    print("llwant, dfreplay, pong")

    local tiles = srAction.tiles
    local actionMeld = {
        tile1 = tiles[1],
        meldType = meldType.enumMeldTypeTriplet,
        contributor = self.latestDiscardedPlayer.chairID
    }

    local actionResultMsg = {targetChairID = srAction.chairID, actionMeld = actionMeld}
    local h = require "scripts/handlers/handlerActionResultPong"
    h.onMsg(actionResultMsg, room)
end
---------------------------------
--明杠
---------------------------------
function Replay:kongExposedActionHandler(srAction, room)
    print("llwant, dfreplay, kong-exposed")
    local tiles = srAction.tiles
    local actionMeld = {
        tile1 = tiles[1],
        meldType = meldType.enumMeldTypeExposedKong,
        contributor = self.latestDiscardedPlayer.chairID
    }

    local actionResultMsg = {targetChairID = srAction.chairID, actionMeld = actionMeld}
    local h = require "scripts/handlers/handlerActionResultKongExposed"
    h.onMsg(actionResultMsg, room)
end
---------------------------------
--暗杠
---------------------------------
function Replay:kongConcealedActionHandler(srAction, room)
    print("llwant, dfreplay, kong-concealed")
    local tiles = srAction.tiles
    local kongTileId = tiles[1]

    local actionResultMsg = {targetChairID = srAction.chairID, actionTile = kongTileId}
    local h = require "scripts/handlers/handlerActionResultKongConcealed"
    h.onMsg(actionResultMsg, room)
end
---------------------------------
--加（续）杠
---------------------------------
function Replay:triplet2KongActionHandler(srAction, room)
    print("llwant, dfreplay, triplet2kong")
    local tiles = srAction.tiles
    local kongTileId = tiles[1]

    local actionResultMsg = {targetChairID = srAction.chairID, actionTile = kongTileId}
    local h = require "scripts/handlers/handlerActionResultTriplet2Kong"
    h.onMsg(actionResultMsg, room)
end
---------------------------------
--吃铳胡牌
---------------------------------
function Replay:winChuckActionHandler(srAction, room)
    print("llwant, dfreplay, win chuck ")
    local player = room:getPlayerByChairID(srAction.chairID)
    player:addHandTile(srAction.tiles[1])
end
---------------------------------
--自摸胡牌
---------------------------------
function Replay:winSelfDrawActionHandler(_, _)
    print("llwant, dfreplay, win self draw ")
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
        msgHandOver.endType = mahjong.HandOverType.enumHandOverType_None
    else
        local handScore = proto.decodeMessage("mahjong.MsgHandScore", handScoreBytes)

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
        p.lastTile = p.tilesHand[#p.tilesHand] --保存最后一张牌，可能是胡牌。。。用于最后结算显示
    end

    local h = require "scripts/handlers/handlerMsgHandOver"
    h.onHandOver(msgHandOver, room)
end

return Replay
