--[[
    Room保存着所有player
    players用chairId索引
]]
--luacheck: no self
local Room = {}

local mt = {__index = Room}

local logger = require "lobby/lcore/logger"
local proto = require "scripts/proto/proto"
local rapidjson = require("rapidjson")
local RoomView = require("scripts/roomView")
local Player = require("scripts/player")
local HandResultView = require("scripts/handResultView")
local GameOverResultView = require("scripts/gameOverResultView")
--local fairy = require "lobby/lcore/fairygui"

-----------------------------------------------------------
--初始化顶层消息响应handlers，有些消息例如ActionResultNotify
--就需要msg handler继续switch case消息体内的action码
-----------------------------------------------------------
local function initMsgHandler()
    local msgHandlers = {}
    local msgCodeEnum = proto.mahjong.MessageCode
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
function Room.new(user, replay)
    local room = {user = user, replay = replay}
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
    return self.replay ~= nil
end

-----------------------------------------------------------
--根据userId找到player对象
--@param userID 64位userid
-----------------------------------------------------------
function Room:getPlayerByUserId(userID)
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
-- 判断player是否玩家自身
-------------------------------------------
function Room:isMe(player)
    return tostring(self.user.userID) == tostring(player.userID)
end

-------------------------------------------
-- 消息分发
-- 主要处理最外层的GameMessage消息结构
-------------------------------------------
function Room:dispatchWeboscketMessage(gmsg)
    local op = gmsg.Ops
    local handler = self.Handlers[op]
    if handler == nil then
        logger.debug(" Room:dispatchWeboscketMessage, no handler for:", op)
        return
    end

    local msgData = gmsg.Data
    logger.debug(" room dispatch msg, op:", gmsg.Ops, ",data size:", #msgData)
    -- 调用handler的onMsg
    handler.onMsg(msgData, self)
end

------------------------------------
--把tilesInWall显示到房间的剩余牌数中
------------------------------------
function Room:updateTilesInWallUI()
    self.roomView.tilesInWall.text = "剩牌 :" .. self.tilesInWall
end

----------------------------------------------
-- 加载房间的view
----------------------------------------------
function Room:loadRoomView()
    local roomView = RoomView.new(self)
    self.roomView = roomView
end

----------------------------------------------
-- 创建玩家对象
-- 并绑定playerView
----------------------------------------------
function Room:createPlayerByInfo(playerInfo)
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
end

function Room:onReadyButtonClick()
    self.host:sendPlayerReadyMsg()
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
    local c = (chairID - myChairId + 4) % 4
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
    local c = (chairID - myChairId + 4) % 4
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
    self:sendMsg(proto.mahjong.MessageCode.OPAction, msgAction)
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
    local gmsg = {}
    gmsg.Ops = opCode

    if msg ~= nil then
        gmsg.Data = msg
    end

    local buf = proto.encodeMessage("mahjong.GameMessage", gmsg)
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
end

--背景声音
--参数：backMusicVolume
function Room:resumeBackMusicVolume()
    --if self:DelayRunCanceled() then
    -- if backMusicVolume then
    --     soundMgr:SetBackMusicVolume(backMusicVolume)
    -- else
    --     soundMgr:SetBackMusicVolume(soundModule.backMusicVolume)
    -- end
    --end
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
        self:sendMsg(proto.mahjong.MessageCode.OPDisbandRequest)
        self.disbandLocked = true
    end
end

---------------------------------------
--更新解散处理界面
---------------------------------------
function Room:updateDisbandVoteView(msgDisbandNotify)
    self.msgDisbandNotify = msgDisbandNotify

    if self.disbandVoteView then
        self.disbandVoteView:updateView(msgDisbandNotify)
    else
        local viewObj = _ENV.thisMod:CreateUIObject("dafeng", "disband_room")
        local disbandVoteView = require("scripts/disbandVoteView")
        self.disbandVoteView = disbandVoteView.new(self, viewObj)
        self.disbandVoteView:updateView(msgDisbandNotify)
    end
end

---------------------------------------
--发送解散回复给服务器
---------------------------------------
function Room:sendDisbandAgree(agree)
    local msgDisbandAnswer = {}
    msgDisbandAnswer.agree = agree
    local buf = proto.encodeMessage("mahjong.MsgDisbandAnswer", msgDisbandAnswer)
    self:sendMsg(proto.mahjong.MessageCode.OPDisbandAnswer, buf)
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

--关闭吃牌，杠牌，听牌详情
function Room:cleanUI()
    -- self.roomView.MultiChiOpsObj.visible = false
    -- self.roomView.MultiGangOpsObj.visible = false
    self.roomView.listensObj.visible = false
    self.roomView.meldOpsPanel.visible = false
end

-----------------------------------------------------------
--设置庄家标志
-----------------------------------------------------------
function Room:setBankerFlag()
    for _, v in pairs(self.players) do
        v.playerView.head.onUpdateBankerFlag(v.chairID == self.bankerChairID, self.isContinuousBanker)
    end
end

function Room:updatePlayerLocation(msgUpdateLocation)
    logger.debug("Room:updatePlayerLocation")
    local userID = msgUpdateLocation.userID
    local player = self.players[userID]
    if not player then
        logger.debug(" updatePlayerLocation, can't find player ", userID)
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
end

function Room:loadHandResultView()
    HandResultView.new(self)
end

function Room:loadGameOverResultView()
    GameOverResultView.new(self)
end

function Room:hideDiscardedTips()
    for _, p in pairs(self.players) do
        p:hideDiscardedTips()
    end
end

function Room:sendDonate(donateId, toChairID)
    -- 1：鲜花    2：啤酒    3：鸡蛋    4：拖鞋
    -- 8：献吻    7：红酒    6：大便    5：拳头
    local chairID = self.myPlayer.chairID

    local msgDonate = {}
    msgDonate.fromChairID = chairID
    msgDonate.toChairID = toChairID
    msgDonate.itemID = donateId

    local actionMsgBuf = proto.encodeMessage("mahjong.MsgDonate", msgDonate)
    self:sendMsg(proto.mahjong.MessageCode.OPDonate, actionMsgBuf)
end

----------------------------------------------
-- 显示道具动画
----------------------------------------------
function Room:showDonate(msgDonate)
    -- logger.debug("显示道具动画 msgDonate : ", msgDonate)
    if msgDonate then
        local itemID = msgDonate.itemID
        local oCurOpObj = self.roomView.donateMoveObj

        local fromPlayer = self:getPlayerByChairID(msgDonate.fromChairID)
        local toPlayer = self:getPlayerByChairID(msgDonate.toChairID)
        if fromPlayer == nil or toPlayer == nil then
            print("llwant, fromPlayer or toPlayer is nil...")
            return
        end
        -- if toPlayer.playerView.headPopup.headInfobg.activeSelf then
        --     --更新界面信息  to的player 主要更新 红心数量
        --     toPlayer.playerView:updateHeadPopup()
        -- end
        -- if fromPlayer.playerView.headPopup.headInfobg.activeSelf then
        --     --更新界面信息  from的player 主要更新 钻石数量
        --     fromPlayer.playerView:updateHeadPopup()
        -- end
        local fromX = fromPlayer.playerView.head.headView.x
        local fromY = fromPlayer.playerView.head.headView.y
        local toX = toPlayer.playerView.head.headView.x
        local toY = toPlayer.playerView.head.headView.y
        -- logger.debug("目标位置 toX : ", toX, " ; toY : ", toY)
        oCurOpObj:SetXY(fromX, fromY)
        oCurOpObj.visible = true
        local sprite = nil
        local effobjSUB = nil
        -- local sound = nil
        local handTypeMap = {
            [1] = function()
                sprite = "dj_meigui"
                effobjSUB = "Effects_daojv_hua"
            end,
            [2] = function()
                sprite = "dj_ganbei"
                effobjSUB = "Effects_daojv_jiubei"
            end,
            [3] = function()
                sprite = "dj_jd"
                effobjSUB = "Effects_daojv_jidan"
            end,
            [4] = function()
                sprite = "dj_tuoxie"
                effobjSUB = "Effects_daojv_tuoxie"
            end,
            [5] = function()
                sprite = "dj_qj"
                effobjSUB = "Effects_daojv_quanji"
            end,
            [6] = function()
                sprite = "dj_bb"
                effobjSUB = "Effects_daojv_shiren"
            end,
            [7] = function()
                sprite = "dj_hj"
                effobjSUB = "Effects_daojv_hongjiu"
            end,
            [8] = function()
                sprite = "dj_mmd"
                effobjSUB = "Effects_daojv_zui"
            end
        }

        local fn = handTypeMap[itemID]
        fn()
        if sprite == nil or effobjSUB == nil then
            print("llwant, sprite or effobjSUB is nil...")
            return
        end
        oCurOpObj.url = "ui://lobby_player_info/" .. sprite
        --飞动画
        oCurOpObj:TweenMove({x = toX, y = toY}, 1)
        self.roomView.unityViewNode:DelayRun(
            1,
            function()
                --飞完之后的回调
                --飞完之后 关闭oCurOpObj
                oCurOpObj.visible = false
                --播放特效
                toPlayer.playerView:playerDonateEffect(effobjSUB)
                --播放声音
                -- if sound ~= nil then
                -- dfCompatibleAPI:soundPlay("daoju/" .. sound)
                -- end
            end
        )
    end
end

return Room
