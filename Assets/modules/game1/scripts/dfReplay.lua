--[[
    控制回播
]]
local DFReplay = {}

local mt = {__index = DFReplay}
local dfPath = "GuanZhang/Script/"
local Room = require(dfPath .. "dfMahjong/room")

local Acc = g_ModuleMgr:GetModule("AccModule")

local bit = require(dfPath .. "dfMahjong/bit")
local dfCompatibleAPI = require(dfPath .. "dfMahjong/dfCompatibleAPI")
require(dfPath .. "Proto/game_pokerface_rf_pb")
local pokerfaceRf = game_pokerface_rf_pb

--local pkproto2 = game_mahjong_s2s_pb

function DFReplay:new(df, userID, msgHandRecord)
    local dfReplay = {}
    setmetatable(dfReplay, mt)

    dfReplay.df = df
    --dfReplay.replayRoom = replayRoom
    dfReplay.msgHandRecord = msgHandRecord
    dfReplay.user = {userID = userID}

    return dfReplay
end

function DFReplay:gogogo(isShare)
    logger.debug(" gogogo")

    --新建room和绑定roomView
    self.room = Room:new(self.user, self)
    self.room.host = self.df
    --self.room.roomInfo = roomInfo

    logger.debug(" room info : " .. self.msgHandRecord.roomConfigID)
    local roomInfo = accessory_pb.RoomInfo {}
    roomInfo.roomID = ""
    roomInfo.roomNumber = self.msgHandRecord.roomNumber
    roomInfo.gameServerURL = ""
    roomInfo.state = 1
    roomInfo.config = self.msgHandRecord.roomConfigID
    roomInfo.timeStamp = ""
    roomInfo.handStartted = self.msgHandRecord.handNum
    roomInfo.lastActiveTime = 0

    self.room.roomInfo = roomInfo
    self.room.handStartted = self.msgHandRecord.handNum
    self.room.roomNumber = self.msgHandRecord.roomNumber

    self.room:loadRoomView()
    coroutine.waitDoFinish(self.room)

    local df = require(dfPath .. "dfMahjong/dfSingleton")
    local dfSingleton = df:getSingleton()

    dfSingleton.room = self.room

    local room = self.room
    --新建player以及绑定playerView
    --先新建自己
    local players = self.msgHandRecord.players
    for _, p in ipairs(players) do
        --if p.userID == acc.userID then
        logger.debug(" p.userID " .. p.userID)
        if p.userID == self.user.userID then
            room:createMyPlayer(p)
        end
    end
    --新建其他人
    for _, p in ipairs(players) do
        --if p.userID ~= acc.userID then
        if p.userID ~= self.user.userID then
            room:createPlayerByInfo(p)
        end
    end

    --挂载action处理handler，复用action result handlers
    self:armActionHandler()
    self.speed = 48 -- 默认速度,每次等待48帧
    self.normalSpeed = self.speed

    self.exit = false
    --循环播放
    while not self.exit do
        --重置房间
        room:resetForNewHand()
        --发牌
        self:deal()
        --隐藏继续按钮
        --显示暂停按钮
        room.roomView:pauseResumeButtons(true, false)

        --循环执行动作列表
        local actionlist = self.msgHandRecord.actions
        for i, a in ipairs(actionlist) do
            if bit.band(a.flags, pokerfaceS2s.SRUserReplyOnly) == 0 then
                self:waitActionDelay()
                if self.pause then
                    self:waitPauseResume()
                end
                if not self.exit then
                    self:doAction(a, actionlist, i)
                else
                    break
                end
            end
        end

        --结算
        if not self.exit then
            if self.pause then
                self:waitPauseResume()
            end
            self:handOver()
        end

        --等待结束，或者重播
        if not self.exit then
            self:waitPauseResume()
        end

        --销毁结算页面
        if self.room.handResultView ~= nil then
            self.room.handResultView:destroy()
            self.room.handResultView = nil
        end
    end
    -- 取消游戏模块的逻辑监听
    -- require "DFMJGame"
    -- DFMJGame.Close()
    -- room.roomView:destroyReplayView()
    dfSingleton.room = nil

    local dispatcher = g_ModuleMgr:GetModule(ModuleName.DISPATCH_MODULE)
    local hallModule = require("HallComponent.Script.HallModule")
    local hm = g_ModuleMgr:GetModule(hallModule.moduleName)
    if not hm then
        g_ModuleMgr:AddModule(hallModule.moduleName, hallModule)
    end

    if isShare then
        --如果是从查看回放的入口进来的，则回到大厅,否则回到会播房间列表页面
        logger.debug("back to hallview")
        dispatcher:dispatch("OPEN_HALLVIEW")
    else
        local function cb()
            dispatcher:dispatch("OPEN_GAME_RECORD_DETAIL_VIEW")
        end
        dispatcher:dispatch("OPEN_HALLVIEW", cb)
    end
end

---------------------------------
--降低速度
---------------------------------
function DFReplay:decreaseSpeed()
    if self.speed >= (4 * self.normalSpeed) then
        dfCompatibleAPI:showTip("已经是最慢速度")
        return
    end

    self.speed = self.speed * 2
    self:showCurrentSpeed()
end
---------------------------------
--增加速度
---------------------------------
function DFReplay:increaseSpeed()
    if self.speed <= (self.normalSpeed / 4) then
        dfCompatibleAPI:showTip("已经是最快速度")
        return
    end

    self.speed = self.speed / 2
    self:showCurrentSpeed()
end
function DFReplay:showCurrentSpeed()
    local scale
    if self.speed <= self.normalSpeed then
        scale = self.normalSpeed / self.speed
        dfCompatibleAPI:showTip("速度X" .. tostring(scale))
    else
        scale = self.speed / self.normalSpeed
        dfCompatibleAPI:showTip("速度/" .. tostring(scale))
    end
end
---------------------------------
--退出房间
---------------------------------
function DFReplay:onExitReplay()
    self.exit = true
    --logError("on exit : "..tostring(self.coWait ~= nil))
    if self.coWait ~= nil then
        self:resumeCo()
    end
end
---------------------------------
--暂停后继续
---------------------------------
function DFReplay:onPauseResume()
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
function DFReplay:onPause()
    self.pause = true

    --隐藏暂停按钮
    --显示继续按钮
    self.room.roomView:pauseResumeButtons(false, true)
end

---------------------------------
--等待继续或者退出房间
---------------------------------
function DFReplay:waitPauseResume()
    --隐藏暂停按钮
    --显示继续按钮
    self.room.roomView:pauseResumeButtons(false, true)

    local coWait = coroutine.running()

    self.coWait = coWait
    coroutine.yield()

    self.coWait = nil
end

---------------------------------
--等待action延时
---------------------------------
function DFReplay:waitActionDelay()
    local coWait = coroutine.running()

    local dfReplay = self

    --local unityViewNode = self.room.roomView.replayUnityViewNode
    --unityViewNode:StartTimer("replayWaitAction", self.speed, function()
    --    dfReplay:resumeCo()
    --end , 0)
    local action = function()
        self.timer:Stop()
        self.timer = nil
        dfReplay:resumeCo()
    end

    self.timer = FrameTimer.New(action, self.speed, -1)
    self.timer:Start()

    self.coWait = coWait
    coroutine.yield()
    --unityViewNode:StopTimer("replayWaitAction")
    if self.timer ~= nil then
        self.timer:Stop()
        self.timer = nil
    end
    self.coWait = nil
end
---------------------------------
--继续coroutine
---------------------------------
function DFReplay:resumeCo()
    --local unityViewNode = self.room.roomView.replayUnityViewNode
    --unityViewNode:StopTimer("replayWaitAction")

    if self.timer ~= nil then
        self.timer:Stop()
        self.timer = nil
    end

    if self.coWait ~= nil then
        local coWait = self.coWait
        local flag, msg = coroutine.resume(coWait)
        if not flag then
            msg = debug.traceback(coWait, msg)
            --error(msg)
            logError(msg)

            return
        end
    end
end
---------------------------------
--发牌
---------------------------------
function DFReplay:deal()
    local room = self.room
    --房间状态改为playing
    room.state = pkproto2.SRoomPlaying
    room.roomView:onUpdateStatus(room.state)

    local deals = self.msgHandRecord.deals
    --保存一些房间属性
    room.bankerChairID = self.msgHandRecord.bankerChairID
    --是否连庄
    room.isContinuousBanker = self.msgHandRecord.isContinuousBanker
    --room.windFlowerID = self.msgHandRecord.windFlowerID

    local player1 = nil
    local player2 = nil
    local mySelf = nil
    --所有玩家状态改为playing
    local players = room.players
    for _, p in pairs(players) do
        p.state = pkproto2.PSPlaying
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

        --drawCount =  drawCount + #v.tilesFlower
        --填充花牌列表
        --player:addFlowerTiles(v.tilesFlower)
    end

    --TODO: 播放投色子动画
    --对局开始动画
    self.coWait = coroutine.running()
    -- room.roomView:gameStartAnimation()
    self.coWait = nil

    if self.exit then
        return
    end

    --播放发牌动画，并使用coroutine等待动画完成
    --self.coWait = coroutine.running()
    --room.roomView:dealAnimation()
    --self.coWait = nil

    if self.exit then
        return
    end

    --显示各个玩家的手牌（对手只显示暗牌）和花牌
    for _, p in pairs(players) do
        p:sortHands()
        p:hand2UI(false, false)
    end

    --播放发牌动画，并使用coroutine等待动画完成
    self.coWait = coroutine.running()
    room.roomView:dealAnimation(mySelf, player1, player2)
    self.coWait = nil

    --等待庄家出牌
    local bankerPlayer = room:getPlayerByChairID(room.bankerChairID)
    room.roomView:setWaitingPlayer(bankerPlayer)
end
---------------------------------
--执行动作
---------------------------------
function DFReplay:doAction(srAction, actionlist, i)
    local room = self.room

    local player = room:getPlayerByChairID(srAction.chairID)
    room.roomView:setWaitingPlayer(player)

    local h = self.actionHandler[srAction.action]
    if h == nil then
        logError("DFReplay, no action handler:" .. tostring(srAction.action))
        return
    end
    if srAction.action == pokerfaceRf.enumActionType_DISCARD then
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
function DFReplay:armActionHandler()
    local handers = {}

    handers[pokerfaceRf.enumActionType_SKIP] = self.skipActionHandler
    handers[pokerfaceRf.enumActionType_DISCARD] = self.discardedActionHandler

    self.actionHandler = handers
end
---------------------------------
--过
---------------------------------
function DFReplay:skipActionHandler(srAction, room)
    logger.debug(" dfreplay, firstReadyHand")

    local actionResultMsg = {targetChairID = srAction.chairID}
    local h = require(dfPath .. "dfMahjong/handlerActionResultSkip")
    h:onMsg(actionResultMsg, room)
end

--深度复制table
local function clone(object)
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
    return _copy(object)
end
---------------------------------
--出牌
---------------------------------
function DFReplay:discardedActionHandler(srAction, room, waitDiscardReAction)
    logger.debug(" dfreplay, discarded")
    --这里要复制table出来用，否则，用户观看完一次回播记录之后，点击重播，srAction.cards会少了第一个元素
    local tiles = clone(srAction.cards)
    local cardHandType = tiles[1]
    table.remove(tiles, 1)
    local actionResultMsg = {
        targetChairID = srAction.chairID,
        actionHand = {cards = tiles, cardHandType = cardHandType},
        waitDiscardReAction = waitDiscardReAction
    }

    local h = require(dfPath .. "dfMahjong/handlerActionResultDiscarded")
    h:onMsg(actionResultMsg, room)
end
---------------------------------
--一手牌结束，显示得分页面
---------------------------------
function DFReplay:handOver()
    local room = self.room
    --TODO:关闭倒计时
    room:stopDiscardCountdown()
    room:hideDiscardedTips()

    local handScoreBytes = self.msgHandRecord.handScore

    local msgHandOver = {continueAble = false}
    if handScoreBytes == nil or #handScoreBytes < 1 then
        msgHandOver.endType = pokerfaceProto.enumHandOverType_None
    else
        local handScore = pokerfaceProto.MsgHandScore()
        handScore:ParseFromString(handScoreBytes)

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

    local h = require "GuanZhang/Script/dfMahjong/handlerMsgHandOver"
    h:onHandOver(msgHandOver, room)
end

return DFReplay
