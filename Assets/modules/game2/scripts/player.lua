--[[
    Player表示一个玩家，只有进入房间才会新建Player
    每个Player首先有其对应的牌数据（其中手牌是不公开的），然后是其对应的界面节点
]]
--luacheck: no self
local Player = {}

local mt = {__index = Player}
local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"
-- local agariIndex = require("scripts/AgariIndex")
local tileMounter = require("scripts/tileImageMounter")
local mjproto = proto.mahjong

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

    player:resetForNewHand()

    return player
end

function Player:isMyUserId(userID)
    return tostring(self.userID) == tostring(userID)
end

function Player:resetForNewHand()
    --玩家打出的牌列表
    self.tilesDiscarded = {}
    --玩家的面子牌组列表
    self.melds = {}
    --玩家的花牌列表
    self.tilesFlower = {}

    --是否起手听牌
    --TODO: 当玩家起手听牌时，当仅仅可以打牌操作时，自动打牌
    self.isRichi = false

    --如果玩家对象是属于当前用户的，而不是对手的
    --则有手牌列表，否则只有一个数字表示对手的手牌张数
    if self:isMe() then
        self.tilesHand = {}
        self.tileCountInHand = nil
    else
        self.tileCountInHand = 0
        self.tilesHand = nil
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
    if self.tilesHand ~= nil then
        table.insert(self.tilesHand, tileID)
    else
        self.tileCountInHand = self.tileCountInHand + 1
    end
end

---------------------------------------
--根据规则排序手牌
---------------------------------------
function Player:sortHands(excludeLast)
    if self.tilesHand ~= nil then
        local last
        if excludeLast then
            last = table.remove(self.tilesHand)
        end
        table.sort(
            self.tilesHand,
            function(x, y)
                return x > y
            end
        )
        if excludeLast then
            table.insert(self.tilesHand, last)
        end
    end
end

function Player:addDicardedTile(tileID)
    print("llwant, add discard:" .. tileID .. ",chairID:" .. self.chairID)
    table.insert(self.tilesDiscarded, tileID)
end

function Player:addDiscardedTiles(tiles)
    for _, v in ipairs(tiles) do
        --插入到队列尾部
        table.insert(self.tilesDiscarded, v)
    end
end

------------------------------------
--从手牌列表中删除一张牌
--如果是对手player，则仅减少计数，因
--对手玩家并没有手牌列表
------------------------------------
function Player:removeTileFromHand(tileID)
    if self.tilesHand ~= nil then
        for k, v in ipairs(self.tilesHand) do
            if v == tileID then
                table.remove(self.tilesHand, k)
                break
            end
        end
    else
        self.tileCountInHand = self.tileCountInHand - 1
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
        print("llwant, removed:" .. removed .. ",expected:" .. tileID)
    end
end

------------------------------------
--新增花牌
--@param tiles 新增加的花牌列表
------------------------------------
function Player:addFlowerTiles(tiles)
    for _, v in ipairs(tiles) do
        --插入到队列尾部
        table.insert(self.tilesFlower, v)
    end
end

------------------------------------
--增加多个手牌
------------------------------------
function Player:addHandTiles(tiles)
    for _, v in ipairs(tiles) do
        --插入到队列尾部
        table.insert(self.tilesHand, v)
    end
end

------------------------------------
--增加一个落地面子牌组
------------------------------------
function Player:addMeld(meld)
    --插入到队列尾部
    table.insert(self.melds, meld)
end

------------------------------------
--利用服务器发下来的暗杠牌组的id列表（明牌）
--更新本地的暗杠牌组列表
------------------------------------
function Player:refreshConcealedMelds(concealedKongIDs)
    local i = 1
    for _, m in ipairs(self.melds) do
        -- MeldType
        if m.meldType == mjproto.MeldType.enumMeldTypeConcealedKong then
            m.tile1 = concealedKongIDs[i]
            i = i + 1
        end
    end
end

------------------------------------
--增加多个落地面子牌组
------------------------------------
function Player:addMelds(melds)
    for _, v in ipairs(melds) do
        --插入到队列尾部
        table.insert(self.melds, v)
    end
end

------------------------------------
--获取一个落地面子牌组
------------------------------------
function Player:getMeld(tileID, meldType)
    for _, v in pairs(self.melds) do
        if v.tile1 == tileID and v.meldType == meldType then
            return v
        end
    end
    return nil
end

------------------------------------
--把手牌列表显示到界面上
--对于自己的手牌，需要排序显示，排序仅用于显示
--排序并不修改手牌列表
--如果房间当前是回播，则其他的人的牌也明牌显示
------------------------------------
function Player:hand2UI(wholeMove)
    --先取消所有手牌显示
    local playerView = self.playerView
    playerView:hideHands()
    if self:isMe() then
        playerView:showHandsForMe(wholeMove)
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
--把花牌列表显示到界面上
------------------------------------
function Player:flower2UI()
    --先取消所有花牌显示
    local playerView = self.playerView
    playerView:hideFlowers()

    playerView:showFlowers()
end

------------------------------------
--把打出的牌列表显示到界面上
------------------------------------
function Player:discarded2UI(newDiscard, waitDiscardReAction)
    local playerView = self.playerView
    playerView:showDiscarded(newDiscard, waitDiscardReAction)
end

------------------------------------
--隐藏打出的牌提示
------------------------------------
function Player:hideDiscardedTips()
    -- if not self.waitDiscardReAction then
    --     return
    -- end
    -- self.waitDiscardReAction = false
    -- local discardTips = self.playerView.discardTips
    -- local discardTipsTile = self.playerView.discardTipsTile
    -- discardTipsTile.visible = false
    -- discardTips.visible = false
end

------------------------------------
--听牌标志
------------------------------------
function Player:richiIconShow(showOrHide)
    self.isRichi = showOrHide
    local playerView = self.playerView
    playerView.head.ting.visible = showOrHide
end
------------------------------------
--播放吃牌动画
------------------------------------
function Player:chowResultAnimation()
    if self:isMe() then
        --隐藏牌组
        self.playerView:hideHands()
        self.playerView:showHandsForMe(true)
    end

    --播放对应音效
    self:playOperationSound(SoundDef.Chow)

    self.playerView:playChowResultAnimation()
end

------------------------------------
--播放碰牌动画
------------------------------------
function Player:pongResultAnimation()
    if self:isMe() then
        --隐藏牌组
        self.playerView:hideHands()
        self.playerView:showHandsForMe(true)
    end

    --播放对应音效
    self:playOperationSound(SoundDef.Pong)

    self.playerView:playPongResultAnimation()
end

------------------------------------
--播放明杠动画
------------------------------------
function Player:exposedKongResultAnimation()
    if self:isMe() then
        --隐藏牌组
        self.playerView:hideHands()
        self.playerView:showHandsForMe(true)
    end

    --播放对应音效
    self:playOperationSound(SoundDef.Kong)

    self.playerView:playExposedKongResultAnimation()
end

------------------------------------
--播放暗杠动画
------------------------------------
function Player:concealedKongResultAnimation()
    if self:isMe() then
        --隐藏牌组
        self.playerView:hideHands()
        self.playerView:showHandsForMe(true)
    end

    --播放对应音效
    self:playOperationSound(SoundDef.Kong)

    self.playerView:playConcealedKongResultAnimation()
end

------------------------------------
--播放加杠动画
------------------------------------
function Player:triplet2KongResultAnimation()
    if self:isMe() then
        --隐藏牌组
        self.playerView:hideHands()
        self.playerView:showHandsForMe(true)
    end

    --播放对应音效
    self:playOperationSound(SoundDef.Kong)

    self.playerView:playTriplet2KongResultAnimation()
end

------------------------------------
--播放抓牌
------------------------------------
function Player:playZhuaPaiAnimation()
    if self:isMe() then
        --隐藏牌组
        self.playerView:hideHands()
        self.playerView:showHandsForMe(true)
    end
    print("播放抓牌，。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。")
    --播放对应音效
    self:playOperationSound(SoundDef.DrawCard)

    self.playerView:playZhuaPaiAnimation()
end

------------------------------------
--播放自摸
------------------------------------
function Player:playZiMoAnimation()
    --播放对应音效
    self:playOperationSound(SoundDef.WinDraw)
    --自摸, 1,3 位置的玩家播放zimo1, 2,4位置的玩家播放zimo2
    -- local effect = dfConfig.EFF_DEFINE.SUB_ZI_ZIMO .. "1"
    -- if self.playerView.viewChairID == 2 or self.playerView.viewChairID == 4 then
    --     effect = dfConfig.EFF_DEFINE.SUB_ZI_ZIMO .. "2"
    -- end
    -- self.playerView:playerOperationEffect(effect)
end

------------------------------------
--播放点炮
------------------------------------
function Player:playDianPaoAnimation()
    --播放对应音效
    self:playOperationSound(SoundDef.WinChuck)
    -- self.playerView:playerOperationEffect(dfConfig.EFF_DEFINE.SUB_ZI_DIANPAO)
end

------------------------------------
--播放吃铳
------------------------------------
function Player:playChiChongAnimation()
    --播放对应音效
    --self:playOperationSound(SoundDef.WinChuck)
    -- self.playerView:playerOperationEffect(dfConfig.EFF_DEFINE.SUB_ZI_HU)
end

------------------------------------
--播放音效
------------------------------------
function Player:playSound(_, _)
    -- local soundName = ""
    -- if self.sex == 1 then
    --     soundName = directory .. "/boy/" .. effectName
    -- else
    --     soundName = directory .. "/girl/" .. effectName
    -- end
    -- dfCompatibleAPI:soundPlay(soundName)
end

------------------------------------
--播放起手听牌特效
------------------------------------
function Player:readyHandEffect()
    --播放对应音效
    -- TODO:没有这个音效，暂时注销 by陈日光
    self:playOperationSound(SoundDef.Ting)
    self.playerView:playReadyHandEffect()
end

------------------------------------
--播放读牌音效
------------------------------------
function Player:playReadTileSound(_)
    -- local index = agariIndex.tileId2ArtId(tileID)
    -- local id = tonumber(index)
    -- if id >= 51 and id <= 58 then
    --     self:playSound("operate", "hua")
    -- else
    --     local effectName = "tile" .. id
    --     if id == 11 then
    --         math.newrandomseed()
    --         effectName = string.format("tile%d_%d", id, math.random(1, 2, 3))
    --     elseif id == 29 then
    --         math.newrandomseed()
    --         effectName = string.format("tile%d_%d", id, math.random(1, 2))
    --     end
    --     self:playSound("tile", effectName)
    -- end
end

------------------------------------
--播放吃碰杠胡听音效
------------------------------------
function Player:playOperationSound(effectName)
    self:playSound("operate", effectName)
    --执行音效
    -- dfCompatibleAPI:soundPlay("effect/" .. SoundDef.Common)
end

------------------------------------
--绑定playerView
--主要是关联playerView，以及显示playerVIew
------------------------------------
function Player:bindView(playerView)
    self.playerView = playerView
    playerView.player = self
    playerView:initCardLists()
    -- if self.nick ~= nil then
    --     playerView.head.nameText.text = "" .. self.nick
    -- end

    -- playerView.head.root.visible = true
    -- playerView.tilesRoot.visible = true

    playerView:showHeadImg()
    playerView:showOwner()
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
    player.headIconURI = playerInfo.headIconURI
    player.ip = playerInfo.ip
    player.location = playerInfo.location
    player.dfHands = playerInfo.dfHands
    player.diamond = playerInfo.diamond
    player.charm = playerInfo.charm
    player.avatarID = playerInfo.avatarID
    -- if self:isMe() and not self.room:isReplayMode() then
    --     local singleton = acc
    --     singleton.charm = playerInfo.charm
    --     g_dataModule:GetUserData():SetCharm(playerInfo.charm)
    -- end
    self.state = playerInfo.state
end

function Player:discardOutTileID(tileID)
    --从手牌移除
    self:removeTileFromHand(tileID)

    --排一下序,sortHands会根据tilesHand表格是否为nil，做出排序选择
    self:sortHands()

    --更新UI
    self:hand2UI()

    --出牌音效
    -- dfCompatibleAPI:soundPlay("effect/effect_chupai")
    --播放读牌音效
    -- if dfCompatibleAPI:soundGetToggle("readPaiIsOn") then
    --     self:playReadTileSound(tileID)
    -- end
end

function Player:myDiscardAction(tileID)
    self:discardOutTileID(tileID)
    self.playerView:enlargeDiscarded(tileID, true)
end

function Player:onBankerReadyHandClicked(_)
    --检查是否选择了牌打出去
    local handsClickCtrls = self.playerView.handsClickCtrls
    for i = 1, 14 do
        local clickCtrl = handsClickCtrls[i]
        if clickCtrl.clickCount == 1 then
            --检查选择了的牌是否可以听
            if clickCtrl.readyHandList ~= nil and #clickCtrl.readyHandList > 0 then
                --如果此牌可以听
                --发送打牌的消息包，把flag设置1，服务器就知道庄家选择了打牌并且听牌
                local actionMsg = {}
                actionMsg.qaIndex = self.allowedActionMsg.qaIndex
                actionMsg.action = mjproto.ActionType.enumActionType_DISCARD
                actionMsg.tile = clickCtrl.tileID
                actionMsg.flags = 1

                --修改：出牌后立即放大打出的牌，一直等待服务器的回复
                self:myDiscardAction(clickCtrl.tileID)

                local tipsForAction = self.allowedActionMsg.tipsForAction
                for _, t in ipairs(tipsForAction) do
                    if t.targetTile == clickCtrl.tileID then
                        local readyHandList = t.readyHandList
                        self:updateReadyHandList(readyHandList)
                        break
                    end
                end
                self.self:sendActionMsg(actionMsg)
                return true
            else
                --TODA 请选择一张可听的牌
                -- logError("请选择一张可听的牌")
                -- dfCompatibleAPI:showTip("请选择一张可听的牌")
                return false
            end

        -- return false
        end
    end
    --TODA 请选择一张可听的牌
    --logError("请选择一张牌")
    -- dfCompatibleAPI:showTip("请选择一张牌")
    return false
end

----------------------------------------
-- 玩家选择了起手听牌   （选择“听”按钮-->隐藏所有动作按钮-->不可听的牌灰度处理-->接下来打出的牌就是听牌）
-- 上下文必然是allowedActionMsg
----------------------------------------
function Player:onReadyHandBtnClick(_)
    local room = self.room
    --隐藏所有动作按钮
    self.playerView:hideOperationButtons()

    if room.bankerChairID == self.chairID then
        --庄家起手听
        --不可听的牌灰度处理
        local handsClickCtrls = self.playerView.handsClickCtrls
        for i = 1, 14 do
            local handsClickCtrl = handsClickCtrls[i]
            local tileID = handsClickCtrl.tileID
            if tileID ~= nil then
                handsClickCtrl.isDiscardable = handsClickCtrl.t.activeSelf
                if not handsClickCtrl.t.activeSelf then
                    handsClickCtrl.isGray = true
                    self.playerView:setGray(handsClickCtrl.h)
                end
            end
        end
        --设置一个标志，接下来打牌就看这个标志
        self.flagsTing = true
        --设置一个标志，表示已经点击了动作按钮（吃碰杠胡过）
        self.waitSkip = false
    else
        --玩家起手听
        local actionMsg = {}
        actionMsg.qaIndex = self.allowedActionMsg.qaIndex
        actionMsg.action = mjproto.ActionType.enumActionType_FirstReadyHand
        actionMsg.flags = 1 --0表示不起手听牌

        self:sendActionMsg(actionMsg)
    end
end

function Player:onFinalDrawBtnClick(_)
    -- local room = self.room

    if self.allowedActionMsg ~= nil then
        local actionMsg = {}
        actionMsg.qaIndex = self.allowedActionMsg.qaIndex
        actionMsg.action = mjproto.ActionType.enumActionType_AccumulateWin
        self:sendActionMsg(actionMsg)
    end

    self.playerView:clearAllowedActionsView()
end

----------------------------------------
-- 玩家选择了起手听牌
-- 上下文必然是allowedActionMsg
----------------------------------------
function Player:onReadyHandBtnClick2(btnObj)
    local room = self.room

    -- 庄家起手听要特殊处理
    -- 先保存一下到hasRichiWill
    -- TODO: 等庄家出牌后带上这个标志
    local isOk = false

    if self.allowedActionMsg ~= nil then
        if room.bankerChairID == self.chairID then
            isOk = self:onBankerReadyHandClicked(btnObj)
        else
            local actionMsg = {}
            actionMsg.qaIndex = self.allowedActionMsg.qaIndex
            actionMsg.action = mjproto.ActionType.enumActionType_FirstReadyHand
            actionMsg.flags = 1 --0表示不起手听牌

            self:sendActionMsg(actionMsg)
            isOk = true
        end
    end
    if isOk then
        self.playerView:clearAllowedActionsView()
    end
end

----------------------------------------
-- 玩家选择了吃牌
-- 上下文必然是allowedReActionMsg
----------------------------------------
function Player:onChowBtnClick(_)
    -- local room = self.room
    if self.allowedReActionMsg ~= nil then
        local actionMsg = {}
        actionMsg.qaIndex = self.allowedReActionMsg.qaIndex
        actionMsg.action = mjproto.ActionType.enumActionType_CHOW

        --必然只有一个可以碰的面子牌组
        --TODO: 吃牌可以有多种吃法
        local ss = self.allowedReActionMsg.meldsForAction
        local chowMelds = self:selectMeldFromMeldsForAction(ss, mjproto.MeldType.enumMeldTypeSequence)
        logger.debug("chowMelds : ", chowMelds)
        actionMsg.tile = self.allowedReActionMsg.victimTileID
        if #chowMelds > 1 then
            self:showMultiOps(chowMelds, actionMsg, 3)
        else
            actionMsg.meldType = chowMelds[1].meldType
            actionMsg.meldTile1 = chowMelds[1].tile1
            self:sendActionMsg(actionMsg)
        end
    end
    self.playerView:clearAllowedActionsView()
end

----------------------------------------
-- 玩家选择了碰牌
-- 上下文必然是allowedReActionMsg
----------------------------------------
function Player:onPongBtnClick(_)
    -- local room = self.room

    if self.allowedReActionMsg ~= nil then
        local actionMsg = {}
        actionMsg.qaIndex = self.allowedReActionMsg.qaIndex
        actionMsg.action = mjproto.ActionType.enumActionType_PONG

        --必然只有一个可以碰的面子牌组
        local ss = self.allowedReActionMsg.meldsForAction
        local pongMelds = self:selectMeldFromMeldsForAction(ss, mjproto.MeldType.enumMeldTypeTriplet)
        actionMsg.tile = self.allowedReActionMsg.victimTileID
        actionMsg.meldType = pongMelds[1].meldType
        actionMsg.meldTile1 = pongMelds[1].tile1

        self:sendActionMsg(actionMsg)
    end

    self.playerView:clearAllowedActionsView()
end

----------------------------------------
-- 玩家选择了杠牌
-- 当上下文是allowedActionMsg时，表示加杠或者暗杠
-- 当上下文是allowedReActionMsg时，表示明杠
----------------------------------------
function Player:onKongBtnClick(_)
    -- local room = self.room

    if self.allowedActionMsg ~= nil then
        local actionMsg = {}
        -- 确定是加杠还是暗杠
        -- if proto.actionsHasAction(self.allowedActionMsg.allowedActions, mjproto.enumActionType_KONG_Concealed) then
        --     action = mjproto.enumActionType_KONG_Concealed
        -- end
        actionMsg.qaIndex = self.allowedActionMsg.qaIndex
        local ss = self.allowedActionMsg.meldsForAction
        local kongConcealed = self:selectMeldFromMeldsForAction(ss, mjproto.MeldType.enumMeldTypeConcealedKong)
        local kongTriplet2 = self:selectMeldFromMeldsForAction(ss, mjproto.MeldType.enumMeldTypeTriplet2Kong)
        local kongs = {}
        local action = mjproto.ActionType.enumActionType_KONG_Triplet2
        if #kongConcealed > 0 then
            action = mjproto.ActionType.enumActionType_KONG_Concealed
            for _, v in pairs(kongConcealed) do
                table.insert(kongs, v)
            end
        end
        if #kongTriplet2 > 0 then
            for _, v in pairs(kongTriplet2) do
                table.insert(kongs, v)
            end
        end

        if #kongs > 1 then
            self:showMultiOps(kongs, actionMsg, 4)
        else
            actionMsg.action = action
            --无论是加杠，或者暗杠，肯定只有一个面子牌组
            actionMsg.tile = kongs[1].tile1
            actionMsg.meldType = kongs[1].meldType
            actionMsg.meldTile1 = kongs[1].tile1
            self:sendActionMsg(actionMsg)
        end
    elseif self.allowedReActionMsg ~= nil then
        local actionMsg = {}
        actionMsg.qaIndex = self.allowedReActionMsg.qaIndex
        actionMsg.action = mjproto.ActionType.enumActionType_KONG_Exposed

        -- 必然只有一个可以明杠的牌组
        local ss = self.allowedReActionMsg.meldsForAction
        local kongExposedMelds = self:selectMeldFromMeldsForAction(ss, mjproto.MeldType.enumMeldTypeExposedKong)
        actionMsg.tile = self.allowedReActionMsg.victimTileID
        actionMsg.meldType = kongExposedMelds[1].meldType
        actionMsg.meldTile1 = kongExposedMelds[1].tile1

        self:sendActionMsg(actionMsg)
    end

    self.playerView:clearAllowedActionsView()
end

function Player:selectMeldFromMeldsForAction(meldsForAction, ty)
    local r = {}
    for _, m in ipairs(meldsForAction) do
        if m.meldType == ty then
            table.insert(r, m)
        end
    end

    return r
end

----------------------------------------
-- 选择如何吃牌，杠牌界面  exp:吃的时候是3，杠的时候是4
----------------------------------------
function Player:showMultiOps(datas, actionMsg2, exp)
    for i = 1, 3 do
        self.playerView.multiOpsObj[i].visible = false
    end
    for i, data in pairs(datas) do
        local oCurOpsObj = self.playerView.multiOpsObj[i]
        oCurOpsObj.name = tostring(data.meldType)
        local actionMsg = {}
        actionMsg.qaIndex = actionMsg2.qaIndex
        actionMsg.action = actionMsg2.action
        actionMsg.tile = actionMsg2.tile
        actionMsg.meldType = data.meldType
        actionMsg.meldTile1 = data.tile1
        if data.meldType == mjproto.ActionType.enumMeldTypeConcealedKong then
            actionMsg.tile = data.tile1
            actionMsg.action = mjproto.ActionType.enumActionType_KONG_Concealed
        elseif data.meldType == mjproto.ActionType.enumMeldTypeTriplet2Kong then
            actionMsg.tile = data.tile1
            actionMsg.action = mjproto.ActionType.enumActionType_KONG_Triplet2
        end
        local MJ = {} --用来显示可选择的牌
        -- local addW = 0 --多选框背景的大小偏移值（杠的背景需要大一点）
        -- local addX = 0 --多选框位置的便宜值（吃的背景比较小，所以往右偏移值要大点）
        if exp == 3 then
            -- addX = 82
            --吃的时候exp是3，所以第4个牌可以隐藏起来
            oCurOpsObj:GetChild("n4").visible = false
            MJ = {data.tile1, data.tile1 + 1, data.tile1 + 2}
        elseif exp == 4 then
            MJ = {data.tile1, data.tile1, data.tile1, data.tile1}
        -- addW = 200
        end
        --吃杠背景大小
        -- if #datas == 2 then
        --     multiOpsRectTransform.sizeDelta = Vector2.New(540 + addW, 200)
        --     -- multiOpsRectTransform.localPosition = Vector3.New(126 + addX,-30 ,0)
        --     multiOpsMaskRectTransform.sizeDelta = Vector2.New(500 + addW, 200)
        -- else
        --     multiOpsRectTransform.sizeDelta = Vector2.New(780 + addW, 200)
        --     -- multiOpsRectTransform.localPosition = Vector3.New(32 + addX, -30 ,0)
        --     multiOpsMaskRectTransform.sizeDelta = Vector2.New(740 + addW, 200)
        -- end
        for j, v in ipairs(MJ) do
            local oCurCard = oCurOpsObj:GetChild("n" .. j)
            tileMounter:mountTileImage(oCurCard, v)
            oCurCard.visible = true
        end
        oCurOpsObj.visible = true
        oCurOpsObj.onClick:Set(
            function(_)
                -- local curOpIndex = tonumber(obj.name)
                self:sendActionMsg(actionMsg)
                self.playerView.operationButtonsRoot.visible = false
                self.playerView.meldOpsPanel.visible = false
            end
        )
    end
    self.playerView.meldOpsPanel.visible = true
end
----------------------------------------
-- 玩家选择了胡牌
-- 当上下文是allowedActionMsg时，表示自摸胡牌
-- 当上下文是allowedReActionMsg时，表示吃铳胡牌
----------------------------------------
function Player:onWinBtnClick(_)
    -- local room = self.room

    if self.allowedActionMsg ~= nil then
        local actionMsg = {}
        actionMsg.qaIndex = self.allowedActionMsg.qaIndex
        actionMsg.action = mjproto.ActionType.enumActionType_WIN_SelfDrawn

        self:sendActionMsg(actionMsg)
    elseif self.allowedReActionMsg ~= nil then
        local actionMsg = {}
        actionMsg.qaIndex = self.allowedReActionMsg.qaIndex
        actionMsg.action = mjproto.ActionType.enumActionType_WIN_Chuck
        actionMsg.tile = self.allowedReActionMsg.victimTileID

        self:sendActionMsg(actionMsg)
    end

    self.playerView:clearAllowedActionsView()
end

----------------------------------------
-- 玩家选择了过
-- 当上下文是allowedActionMsg时，表示不起手听牌
-- 当上下文是allowedReActionMsg时，表示不吃椪杠胡
----------------------------------------
function Player:onSkipBtnClick(_)
    local room = self.room
    -- local playerView = self.playerView
    local allowedActions = self.allowedActionMsg.allowedActions
    if self.isGuoHuTips then
        -- dfCompatibleAPI:showTip("可胡牌时，需要点击2次过才可过牌。")
        -- 提示完成，设置开关为true
        self.isGuoHuTips = false
    else
        local discardAble = false
        if self.allowedActionMsg ~= nil then
            discardAble = true
            if proto.actionsHasAction(allowedActions, mjproto.ActionType.enumActionType_FirstReadyHand) then
                if room.bankerChairID ~= self.chairID then
                    local actionMsg = {}
                    actionMsg.qaIndex = self.allowedActionMsg.qaIndex
                    --这里action换成enumActionType_FirstReadyHand而不是skip
                    actionMsg.action = mjproto.ActionType.enumActionType_FirstReadyHand
                    actionMsg.flags = 0 --0表示不起手听牌

                    self:sendActionMsg(actionMsg)
                    discardAble = false
                end
            elseif proto.actionsHasAction(allowedActions, mjproto.ActionType.enumActionType_SKIP) then
                if proto.actionsHasAction(allowedActions, mjproto.ActionType.enumActionType_DISCARD) == false then
                    local actionMsg = {}
                    actionMsg.qaIndex = self.allowedActionMsg.qaIndex
                    actionMsg.action = mjproto.ActionType.enumActionType_SKIP

                    self:sendActionMsg(actionMsg)

                    discardAble = false
                end
            end
        elseif self.allowedReActionMsg ~= nil then
            local actionMsg = {}
            actionMsg.qaIndex = self.allowedReActionMsg.qaIndex
            actionMsg.action = mjproto.ActionType.enumActionType_SKIP

            self:sendActionMsg(actionMsg)
        end

        self.playerView:clearAllowedActionsView(discardAble)
        --重置手牌位置
        self.playerView:restoreHandPositionAndClickCount()
        --设置一个标志，表示已经点击了动作按钮（吃碰杠胡过）
        self.waitSkip = false
    end
end

function Player:sendActionMsg(actionMsg)
    local actionMsgBuf = proto.encodeMessage("mahjong.MsgPlayerAction", actionMsg)
    self.room:sendActionMsg(actionMsgBuf)
end

-----------------------------------------------------------
--线程等待
-----------------------------------------------------------
function Player:waitSecond(_)
    -- local waitCo = coroutine.running()
    -- StartTimer(
    --     someSecond,
    --     function()
    --         local flag, msg = coroutine.resume(waitCo)
    --         if not flag then
    --             logError(msg)
    --             return
    --         end
    --     end,
    --     1,
    --     true
    -- )
    -- coroutine.yield()
end
-----------------------------------------------------------
--执行自动打牌操作
-----------------------------------------------------------
function Player:autoDiscard()
    self:waitSecond(1)
    if self.allowedActionMsg ~= nil then
        --自己摸牌的情况下
        local actions = self.allowedActionMsg.allowedActions
        --如果可以自摸胡牌
        --不再自动胡牌，考虑到如果可以胡，可以过，如果帮助用户选择胡可能不是最优选择
        if proto.actionsHasAction(actions, mjproto.ActionType.enumActionType_WIN_SelfDrawn) then
            --self:onWinBtnClick(self.playerView.winBtn)
            --可以胡牌，得返回，让用户自己处理
            return
        end
        --如果不可以胡牌
        local discarAbleTiles = self.allowedActionMsg.tipsForAction
        if #discarAbleTiles == 1 then
            --当且仅当可出牌数为1的时候，才能执行自动打牌
            local discarAbleTile = discarAbleTiles[1]
            local tileID = discarAbleTile.targetTile
            self:onPlayerDiscardTile(tileID)
            self.playerView:clearAllowedActionsView()
        end
    end

    -- if self.allowedReActionMsg ~= nil then
    --当有可以吃碰杠胡的情况
    --自动打牌只处理可以胡的情况，考虑到如果可以胡，可以过，如果帮助用户选择胡可能不是最优选择
    -- local actions = self.allowedReActionMsg.allowedActions
    -- if proto.actionsHasAction(actions, mjproto.enumActionType_WIN_Chuck) then
    --     self:onWinBtnClick(self.playerView.winBtn)
    -- end
    -- end
end

function Player:onPlayerDiscardTile(tileID)
    -- local room = self.room
    print("llwant, discard tile:" .. tileID)
    if self.allowedActionMsg ~= nil then
        local actionMsg = {}
        actionMsg.qaIndex = self.allowedActionMsg.qaIndex
        actionMsg.action = mjproto.ActionType.enumActionType_DISCARD
        actionMsg.tile = tileID
        if self.flagsTing then
            actionMsg.flags = 1
            self.flagsTing = false
        end
        self:sendActionMsg(actionMsg)
        --修改：出牌后立即放大打出的牌，一直等待服务器的回复
        self:myDiscardAction(tileID)

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

function Player:updateReadyHandList(_)
    -- self.readyHandList = readyHandList
    -- if self.readyHandList ~= nil and #self.readyHandList > 0 then
    --     self.playerView.checkReadyHandBtn.visible = true
    -- else
    --     self.playerView.checkReadyHandBtn.visible = false
    -- end
end

return Player
