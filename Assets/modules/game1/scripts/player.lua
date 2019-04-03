--[[
    Player表示一个玩家，只有进入房间才会新建Player
    每个Player首先有其对应的牌数据（其中手牌是不公开的），然后是其对应的界面节点
]]
local Player = {}
Player.VERSION = "1.0"

local logger = require "lobby/lcore/logger"
local mt = {__index = Player}
local proto = require "scripts/proto/proto"
local agariIndex = require("scripts/AgariIndex")
local pokerfaceRf = proto.prunfast
local pokerface = proto.pokerface

--音效文件定义
local SoundDef = {
    Chow = "chi",
    Pong = "peng",
    Kong = "gang",
    Ting = "ting",
    WinChuck = "hu", --被点炮
    WinDraw = "zimo", --自摸
    Common = "effect_common"
}

function Player.new(userID, chairID, room)
    local player = {userID = userID, chairID = chairID, room = room}
    setmetatable(player, mt)

    player.tipCards = nil
    player.tipCardsIndex = 0

    player:resetForNewHand()

    return player
end

function Player:isMyUserId(userID)
    return self.userID == userID
end

function Player:resetForNewHand()
    --玩家打出的牌列表
    self.tilesDiscarded = {}
    --玩家的面子牌组列表
    --self.melds = {}
    --玩家的花牌列表
    --self.tilesFlower = {}

    --是否起手听牌
    --TODO: 当玩家起手听牌时，当仅仅可以打牌操作时，自动打牌
    --self.isRichi = false

    --如果玩家对象是属于当前用户的，而不是对手的
    --则有手牌列表，否则只有一个数字表示对手的手牌张数
    if self:isMe() then
        self.cardsOnHand = {}
        self.cardCountOnHand = nil
    else
        self.cardCountOnHand = 0
        self.cardsOnHand = nil
    end

    -- 如果视图存在，则重置视图
    if self.playerView ~= nil then
        self.playerView:resetForNewHand()
    end
end

------------------------------------
--player对象是当前用户的，抑或是对手的
------------------------------------
function Player:isMe()
    return self.room:isMe(self)
end

function Player:addHandTile(tileID)
    if self.cardsOnHand ~= nil then
        table.insert(self.cardsOnHand, tileID)
    else
        self.cardCountOnHand = self.cardCountOnHand + 1
    end
end

---------------------------------------
--根据规则排序手牌
---------------------------------------
function Player:sortHands(excludeLast)
    if self.cardsOnHand ~= nil then
        -- local last
        -- if excludeLast then
        --     last = table.remove(self.cardsOnHand)
        -- end
        table.sort(
            self.cardsOnHand,
            function(x, y)
                if x == pokerface.CardID.R2H then
                    --为了让 红桃2 排最后
                    return false
                end
                if y == pokerface.CardID.R2H then
                    --为了让 红桃2 排最后
                    return true
                end
                -- if x == pokerface.R3H or y == pokerface.R3H then
                --     self.haveR3H = true
                -- end
                return x < y
            end
        )
    -- if excludeLast then
    --     table.insert(self.cardsOnHand, last)
    -- end
    end
end

function Player:addDicardedTile(tileID)
    table.insert(self.tilesDiscarded, tileID)
end

function Player:addDiscardedTiles(tiles)
    if tiles then
        for _, v in ipairs(tiles) do
            --插入到队列尾部
            table.insert(self.tilesDiscarded, v)
        end
    end
end

------------------------------------
--从手牌列表中删除一张牌
--如果是对手player，则仅减少计数，因
--对手玩家并没有手牌列表
------------------------------------
function Player:removeTileFromHand(tileID)
    if self.cardsOnHand ~= nil then
        for k, v in ipairs(self.cardsOnHand) do
            if v == tileID then
                table.remove(self.cardsOnHand, k)
                break
            end
        end
    else
        self.cardCountOnHand = self.cardCountOnHand - 1
    end
end

------------------------------------
--从打出的牌列表中移除最后一张
--@param tileID 最后一张牌的id，用于assert
------------------------------------
function Player:removeLatestDiscarded(tileID)
    --从队列尾部删除
    local removed = table.remove(self.tilesDiscarded)
    if removed ~= tileID then
        logger.debug(" removed:" .. removed .. ",expected:" .. tileID)
    end
end

------------------------------------
--增加多个手牌
------------------------------------
function Player:addHandTiles(tiles)
    for _, v in ipairs(tiles) do
        --插入到队列尾部
        table.insert(self.cardsOnHand, v)
    end
end

------------------------------------
--把手牌列表显示到界面上
--对于自己的手牌，需要排序显示，排序仅用于显示
--排序并不修改手牌列表
--如果房间当前是回播，则其他的人的牌也明牌显示
------------------------------------
function Player:hand2UI(wholeMove, isShow)
    --先取消所有手牌显示
    local playerView = self.playerView
    playerView:hideHands()

    if self:isMe() then
        playerView:showHandsForMe(wholeMove, isShow)
    else
        if self.room:isReplayMode() then
            playerView:hand2Exposed(wholeMove)
        else
            playerView:showHandsForOpponents()
        end
    end
end

------------------------------------
--把牌摊开
------------------------------------
function Player:hand2Exposed()
    local playerView = self.playerView
    playerView:hideHands()

    playerView:hand2Exposed()
end

------------------------------------
--把打出的牌列表显示到界面上
----------------------------------
function Player:discarded2UI(discardTileIds)
    local playerView = self.playerView
    playerView:showDiscarded(discardTileIds)
end
--显示打出去的牌的类型。。。
function Player:showCardHandType(cardHandType, discardTileId)
    local tip = ""
    local effectName = "" -- 音效
    if cardHandType == pokerfaceRf.CardHandType.Flush then
        tip = dfConfig.EFF_DEFINE.SUB_GUANZHANG_SHUNZI
        --顺子
        effectName = "sunzi"
    elseif cardHandType == pokerfaceRf.CardHandType.Bomb then
        tip = dfConfig.EFF_DEFINE.SUB_GUANZHANG_ZHADAN
        --炸弹
        effectName = "zhadan"
    elseif cardHandType == pokerfaceRf.CardHandType.Single then
        tip = "" --单张
        self:playReadTileSound(discardTileId, false)
    elseif cardHandType == pokerfaceRf.CardHandType.Pair then
        tip = "" --对子
        self:playReadTileSound(discardTileId, true)
    elseif cardHandType == pokerfaceRf.Pair2X then
        tip = dfConfig.EFF_DEFINE.SUB_GUANZHANG_LIANDUI
        --连对
        effectName = "liandui"
    elseif cardHandType == pokerfaceRf.CardHandType.Triplet then
        tip = ""
        --三张
        self:playSound("sange")
    elseif cardHandType == pokerfaceRf.CardHandType.TripletPair then
        tip = dfConfig.EFF_DEFINE.SUB_GUANZHANG_SANDAIER --三带二
        effectName = "sandaiyi"
    elseif cardHandType == pokerfaceRf.CardHandType.Triplet2X then
        tip = dfConfig.EFF_DEFINE.SUB_GUANZHANG_SANLIANDUI -- 飞机
        effectName = "feiji"
    elseif cardHandType == pokerfaceRf.CardHandType.Triplet2X2Pair then
        tip = dfConfig.EFF_DEFINE.SUB_GUANZHANG_HANG --夯加飞机
        effectName = "feijidaicibang"
    end
    if tip ~= "" then
        self.playerView:playerOperationEffectWhitGZ(tip, effectName)
    end
end

------------------------------------
--隐藏打出的牌提示
------------------------------------
function Player:hideDiscardedTips()
    if not self.waitDiscardReAction then
        return
    end

    self.waitDiscardReAction = false
    local discardTips = self.playerView.discardTips
    local discardTipsTile = self.playerView.discardTipsTile
    discardTipsTile:SetActive(false)
    discardTips:SetActive(false)
end

------------------------------------
--播放音效
------------------------------------
function Player:playSound(effectName)
    if effectName ~= nil and effectName ~= "" then
        local gender = "loc_"
        local path = "localize/"
        if self.sex == 1 then
            gender = gender .. "boy"
            path = path .. "boy/"
        else
            gender = gender .. "girl"
            path = path .. "girl/"
        end
        local asset = string.format("%s_%s", gender, effectName)
        -- if isMp3 then
        --     dfCompatibleAPI:soundPlayMp3(path .. asset)
        --     return
        -- end
        dfCompatibleAPI:soundPlay(path .. asset)
    end
end

------------------------------------
--播放读牌音效
------------------------------------
function Player:playReadTileSound(tileID, isDuiZi)
    local artID = agariIndex.tileId2ArtId(tileID)
    local dianShu = math.floor(artID / 4) + 2
    local effectName = tostring(dianShu)
    if dianShu == 14 then
        effectName = "1"
    end
    if isDuiZi then
        effectName = "dui" .. effectName
    end
    self:playSound(effectName)
end
------------------------------------
--播放吃碰杠胡听音效
------------------------------------
function Player:playOperationSound(effectName)
    self:playSound(effectName)
    --执行音效
    dfCompatibleAPI:soundPlay("effect/" .. SoundDef.Common)
end

------------------------------------
--绑定playerView
--主要是关联playerView，以及显示playerVIew
------------------------------------
function Player:bindView(playerView)
    self.playerView = playerView
    playerView.player = self
    if self.nick ~= nil then
        playerView.head.scoreText.text = "" .. self.nick
    end

    -- playerView.head.root:SetActive(true)
    -- playerView.tilesRoot:SetActive(true)

    playerView:showHeadImg()
    -- playerView:showOwner()
end

------------------------------------
--解除绑定playerView
--主要是取消关联playerView，以及隐藏playerVIew
------------------------------------
function Player:unbindView()
    local playerView = self.playerView
    if playerView ~= nil then
        playerView.player = nil
        self.playerView = nil
        playerView:hideAll()
    end
end

function Player:updateByPlayerInfo(playerInfo)
    --TODO: 更新用户状态
    local player = self
    player.sex = playerInfo.sex
    player.dan = playerInfo.dan
    player.headIconURI = playerInfo.headIconURI
    player.ip = playerInfo.ip
    player.location = playerInfo.location
    player.dfHands = playerInfo.dfHands
    player.diamond = playerInfo.diamond
    player.charm = playerInfo.charm
    player.avatarID = playerInfo.avatarID
    player.groupIds = playerInfo.clubIDs
    logger.debug("player.avatarID:" .. tostring(player.avatarID))
    -- if self:isMe() and not self.room:isReplayMode() then
    --     local singleton = acc
    --     singleton.charm = playerInfo.charm
    --     g_dataModule:GetUserData():SetCharm(playerInfo.charm)
    -- end
    self.state = playerInfo.state
    logger.debug("player id:" .. player.userID .. ", avatarID:" .. player.avatarID)
    self:updateHeadEffectBox()
end

----------------------------------------
-- 玩家选择提示
-- 上下文必然是allowedReActionMsg
----------------------------------------
function Player:onTipBtnClick(isHui, btnObj)
    --if isHui then return end
    self.playerView:restoreHandPositionAndClickCount()
    local room = self.room
    local tipCards = self.tipCards
    local handsClickCtrls = self.playerView.handsClickCtrls
    if tipCards == nil then
        local cards = {}
        for i = 1, 16 do
            local handsClickCtrl = handsClickCtrls[i]
            if handsClickCtrl.tileID ~= nil then
                table.insert(cards, handsClickCtrl.tileID)
            end
        end
        local specialCardID = -1
        if self.discardR2H then
            specialCardID = 1
        end
        if self.allowedReActionMsg == nil then
            --提示  自己的出牌提示
            tipCards = agariIndex.searchLongestDiscardCardHand(cards, specialCardID)
        else
            local prevActionHand = self.allowedReActionMsg.prevActionHand
            tipCards = agariIndex.findAllGreatThanCardHands(prevActionHand, cards, specialCardID)
        end
        self.tipCards = tipCards
    end
    if #tipCards == 0 then
        --如果提示没东西，则帮用户
        self:onSkipBtnClick(false, self.playerView.skipBtn)
        return
    end
    if self.tipCardsIndex > #tipCards then
        self.tipCardsIndex = 1
    else
        self.tipCardsIndex = self.tipCardsIndex + 1
    end
    local tipCard = tipCards[self.tipCardsIndex]
    if tipCard then
        local cs = tipCard.cards
        logger.debug(tostring(self.tipCardsIndex) .. "提示 cs : " .. tostring(cs))
        if cs then
            for i = 1, 16 do
                local handsClickCtrl = handsClickCtrls[i]
                local tileID = handsClickCtrl.tileID
                if tileID ~= nil then
                    for k = 1, #cs do
                        if cs[k] == tileID then
                            self.playerView:moveHandUp(i)
                        end
                    end
                end
            end
        end
    end
end
----------------------------------------
-- 玩家选择出牌
----------------------------------------
function Player:onDiscardBtnClick(isHui, btnObj)
    if isHui then
        --提示。。。无牌可出
        logger.error("ERR_ROOM_NOTDISCARDS")
        -- dfCompatibleAPI:showTip(dfConfig.ErrorInRoom.ERR_ROOM_NOTDISCARDS)
        return
    end
    --出牌逻辑
    local handsClickCtrls = self.playerView.handsClickCtrls
    local discardCards = {}
    for i = 1, 16 do
        local handsClickCtrl = handsClickCtrls[i]
        if handsClickCtrl.tileID ~= nil then
            if handsClickCtrl.clickCount == 1 then
                table.insert(discardCards, handsClickCtrl.tileID)
            end
        end
    end
    self:onPlayerDiscardCards(discardCards)
end

----------------------------------------
-- 玩家选择了过
-- 当上下文是allowedActionMsg时，表示不起手听牌
-- 当上下文是allowedReActionMsg时，表示不吃椪杠胡
----------------------------------------
function Player:onSkipBtnClick(isHui, btnObj)
    if isHui then
        --提示 不可以过
        if self.allowedActionMsg ~= nil then
            dfCompatibleAPI:showTip(dfConfig.ErrorInRoom.ERR_ROOM_NOTSKIP_2)
            return
        end
        dfCompatibleAPI:showTip(dfConfig.ErrorInRoom.ERR_ROOM_NOTSKIP)
        return
    end
    local room = self.room

    local discardAble = false

    local actionMsg = {} -- pokerface.MsgPlayerAction()
    actionMsg.qaIndex = self.allowedReActionMsg.qaIndex
    actionMsg.action = pokerfaceRf.ActionType.enumActionType_SKIP
    local actionMsgBuf = proto.encodeMessage("pokerface.MsgPlayerAction", actionMsg)
    room:sendActionMsg(actionMsgBuf)

    self.playerView:clearAllowedActionsView(discardAble)
    --重置手牌位置
    self.playerView:restoreHandPositionAndClickCount()
    --设置一个标志，表示已经点击了动作按钮（吃碰杠胡过）
    self.waitSkip = false

    --隐藏包牌文字警告
    -- self.room.roomView.baopai:SetActive(false)
end

-----------------------------------------------------------
--线程等待
-----------------------------------------------------------
function Player:waitSecond(someSecond)
    local waitCo = coroutine.running()
    StartTimer(
        someSecond,
        function()
            local flag, msg = coroutine.resume(waitCo)
            if not flag then
                logError(msg)
                return
            end
        end,
        1,
        true
    )
    coroutine.yield()
end
-----------------------------------------------------------
--执行自动打牌操作
-----------------------------------------------------------
function Player:autoDiscard()
    self:waitSecond(1)
    if self.allowedActionMsg ~= nil then
    end

    if self.allowedReActionMsg ~= nil then
        -- local actionMsg = pokerface.MsgPlayerAction()
        -- actionMsg.action = pokerfaceRf.enumActionType_DISCARD
        -- actionMsg.qaIndex = self.allowedReActionMsg.qaIndex
        -- table.insert(actionMsg.cards, pokerface.R2H)
        -- self.room:sendActionMsg(actionMsg)
        -- self.discardR2H = false
        -- self.playerView:clearAllowedActionsView()

        local disCards = {pokerface.CardID.R2H}
        self:onPlayerDiscardCards(disCards)
    end
end
function Player:onPlayerDiscardCards(disCards)
    logger.debug(" onPlayerDiscardCards tile .")
    --dump(disCards , "----------------- disCards ---------------------------")
    if disCards == nil or #disCards < 1 then
        logger.error(" ERR_ROOM_NOTSELECTCARDS .")
        -- dfCompatibleAPI:showTip(dfConfig.ErrorInRoom.ERR_ROOM_NOTSELECTCARDS)
        return
    end
    local actionMsg = {} -- pokerface.MsgPlayerAction()
    local r3h = false
    local current = agariIndex.agariConvertMsgCardHand(disCards)
    if current == nil then
        logger.error(" ERR_ROOM_CARDSNOTDIS .")
        -- dfCompatibleAPI:showTip(dfConfig.ErrorInRoom.ERR_ROOM_CARDSNOTDIS)
        return
    end

    local cards_ = {}
    actionMsg.cards = {}
    for i = 1, #disCards do
        local disCard = disCards[i]
        if disCard == pokerface.CardID.R3H then
            r3h = true
        end
        --cards_.append(disCard)
        --actionMsg.cards.append(1)
        table.insert(actionMsg.cards, disCard)
    end
    actionMsg.action = pokerfaceRf.ActionType.enumActionType_DISCARD
    if self.allowedActionMsg ~= nil then
        actionMsg.qaIndex = self.allowedActionMsg.qaIndex
        if self.haveR3H then
            --此时必须出 红桃3
            if not r3h then
                logger.error("ERR_ROOM_NOTDISCARDSR3H")
                -- dfCompatibleAPI:showTip(dfConfig.ErrorInRoom.ERR_ROOM_NOTDISCARDSR3H)
                return
            end
            self.haveR3H = false
        end
    end

    if self.allowedReActionMsg ~= nil then
        actionMsg.qaIndex = self.allowedReActionMsg.qaIndex
        local prevActionHand = self.allowedReActionMsg.prevActionHand
        if self.discardR2H then
            --此时必须出2
            if #disCards ~= 1 or disCards[1] ~= pokerface.CardID.R2H then
                logger.error("ERR_ROOM_NOTDISCARDSR2H")
                -- dfCompatibleAPI:showTip(dfConfig.ErrorInRoom.ERR_ROOM_NOTDISCARDSR2H)
                return
            end
            self.discardR2H = false
        end
        if not agariIndex.agariGreatThan(prevActionHand, current) then
            logger.error("ERR_ROOM_DISCARDISSMALL")
            -- dfCompatibleAPI:showTip(dfConfig.ErrorInRoom.ERR_ROOM_DISCARDISSMALL)
            return
        end
    end
    local actionMsgBuf = proto.encodeMessage("pokerface.MsgPlayerAction", actionMsg)
    self.room:sendActionMsg(actionMsgBuf)
    self.playerView:clearAllowedActionsView()

    --隐藏包牌文字警告
    -- self.room.roomView.baopai:SetActive(false)
end

function Player:onPlayerDiscardTile(tileID)
    local room = self.room
    logger.debug(" discard tile:" .. tileID)
    if self.allowedActionMsg ~= nil then
        local actionMsg = pokerface.MsgPlayerAction()
        actionMsg.qaIndex = self.allowedActionMsg.qaIndex
        actionMsg.action = pokerfaceRf.ActionType.enumActionType_DISCARD
        actionMsg.cards = {tileID}
        -- if self.flagsTing then
        --     actionMsg.flags = 1
        --     self.flagsTing = false
        -- end
        room:sendActionMsg(actionMsg)

        local tipsForAction = self.allowedActionMsg.tipsForAction
        for _, t in ipairs(tipsForAction) do
            if t.targetTile == tileID then
                local readyHandList = t.readyHandList
                self:updateReadyHandList(readyHandList)
                break
            end
        end
    end
    return true
end

function Player:updateHeadEffectBox()
    if self.playerView == nil then
        return
    end

    self.playerView:updateHeadEffectBox()
end

return Player
