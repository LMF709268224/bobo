--[[
    playerview对应玩家的视图，牌桌上有4个playerview
]]
--luacheck: no self
local PlayerView = {}

local mt = {__index = PlayerView}
--local fairy = require "lobby/lcore/fairygui"
local logger = require "lobby/lcore/logger"
local proto = require "scripts/proto/proto"
local animation = require "lobby/lcore/animations"
local tileMounter = require("scripts/tileImageMounter")
local mjproto = proto.mahjong

--面子牌组资源 前缀
local MeldComponentPrefix = {
    [1] = "mahjong_mine_meld_",
    [2] = "mahjong_right_meld_",
    [3] = "mahjong_dui_meld_",
    [4] = "mahjong_left_meld_"
}

--面子牌组资源 后缀
local MeldComponentSuffix = {
    [mjproto.MeldType.enumMeldTypeTriplet2Kong] = "gang1",
    [mjproto.MeldType.enumMeldTypeExposedKong] = "gang1",
    [mjproto.MeldType.enumMeldTypeConcealedKong] = "gang2",
    [mjproto.MeldType.enumMeldTypeSequence] = "chipeng",
    [mjproto.MeldType.enumMeldTypeTriplet] = "chipeng"
}
-----------------------------------------------
-- 新建一个player view
-- @param viewUnityNode 根据viewUnityNode获得playerView需要控制
-- 的所有节点
-----------------------------------------------
function PlayerView.new(viewUnityNode, viewChairID)
    local playerView = {}
    setmetatable(playerView, mt)
    playerView.viewChairID = viewChairID
    playerView.viewUnityNode = viewUnityNode
    -- 这里需要把player的chairID转换为游戏视图中的chairID，这是因为，无论当前玩家本人
    -- 的chair ID是多少，他都是居于正中下方，左手是上家，右手是下家，正中上方是对家
    local view = viewUnityNode:GetChild("player" .. viewChairID)
    playerView.myView = view
    if (viewChairID == 1) then
        playerView.operationPanel = viewUnityNode:GetChild("operationPanel")

        playerView:initOperationButtons()
    end
    playerView.aniPos = view:GetChild("aniPos")

    -- 打出的牌放大显示
    playerView.discardTips = view:GetChild("discardTip")
    playerView.discardTipsTile = playerView.discardTips:GetChild("card")

    -- 头像相关
    playerView:initHeadView()
    -- 玩家状态
    playerView:initPlayerStatus()

    return playerView
end

function PlayerView:initFlowers()
    -- 花牌列表
    -- TODO: 先拿这个hu牌列表来当做花牌列表，hu牌列表只有10个，花牌最多
    -- 时候会有12个，4个当做花牌的风牌+8个花牌
    local flowers = {}
    local myFlowerTilesNode = self.myView:GetChild("flowers")
    for i = 1, 12 do
        local h = myFlowerTilesNode:GetChild("n" .. i)
        flowers[i] = h
    end
    self.flowers = flowers
end

function PlayerView:initLights()
    -- 下面这个Light得到的牌表，是用于结局时摊开牌给其他人看
    local lights = {}
    local myLightTilesNode = self.myView:GetChild("lights")
    for i = 1, 14 do
        local h = myLightTilesNode:GetChild("n" .. i)
        lights[i] = h
    end
    self.lights = lights
end

function PlayerView:initDiscards()
    -- 打出的牌列表
    local discards = {}
    local myDicardTilesNode = self.myView:GetChild("discards")
    for i = 1, 20 do
        local card = myDicardTilesNode:GetChild("n" .. i)
        discards[i] = card
    end
    self.discards = discards
end

function PlayerView:initHands()
    -- 手牌列表
    local hands = {}
    local handsOriginPos = {}
    local handsClickCtrls = {}
    local myHandTilesNode = self.myView:GetChild("hands")
    -- local resName = ""
    local isMe = self.viewChairID == 1
    for i = 1, 14 do
        local card = myHandTilesNode:GetChild("n" .. i)

        card.name = tostring(i) --把手牌按钮对应的序号记忆，以便点击时可以识别
        card.visible = false
        hands[i] = card

        local pos = {}
        pos.x = card.x
        pos.y = card.y

        table.insert(handsOriginPos, pos)
        table.insert(handsClickCtrls, {clickCount = 0, h = card, t = card:GetChild("ting")})

        if isMe then
            --订阅点击事件
            --TODO: 增加drag/drop
            card.onClick:Set(
                function(obj)
                    self:onHandTileBtnClick(obj, i)
                end
            )
            self:onDrag(card, i)
        end
    end

    self.hands = hands
    self.handsOriginPos = handsOriginPos --记忆原始的手牌位置，以便点击手牌时可以往上弹起以及恢复
    self.handsClickCtrls = handsClickCtrls -- 手牌点击时控制数据结构
end

function PlayerView:initCardLists()
    -- 手牌列表
    self:initHands()
    -- 出牌列表
    self:initDiscards()
    -- 花牌列表
    self:initFlowers()
    -- 明牌列表
    self:initLights()
end

-------------------------------------------------
--保存操作按钮
-------------------------------------------------
function PlayerView:initOperationButtons()
    self.buttonList = self.operationPanel:GetChild("buttonList").asList
    self.buttonList.itemRenderer = function(index, obj)
        self:renderButtonListItem(index, obj)
    end
    self.buttonList.itemProvider = function(index)
        return self.buttonDataList[index + 1]
    end
    self.buttonList.onClickItem:Add(
        function(onClickItem)
            self:onClickBtn(onClickItem.data.name)
        end
    )
    self.operationButtonsRoot = self.operationPanel

    self:hideOperationButtons()

    -- 检查听详情 按钮
    self.checkReadyHandBtn = self.viewUnityNode:GetChild("checkReadyHandBtn")
    self.checkReadyHandBtn.onClick:Set(
        function(_)
            self:onCheckReadyHandBtnClick()
        end
    )
end

function PlayerView:renderButtonListItem(index, obj)
    local name = self.buttonDataList[index + 1]
    obj.name = name
    obj.visible = true
end

function PlayerView:showButton(map)
    self.buttonDataList = map
    self.buttonList.numItems = #map
    self.buttonList:ResizeToFit(#map)
    self.operationButtonsRoot.visible = true
end

function PlayerView:onClickBtn(name)
    local player = self.player
    if name == player.ButtonDef.Chow then
        player:onChowBtnClick()
    elseif name == player.ButtonDef.Kong then
        player:onKongBtnClick()
    elseif name == player.ButtonDef.Skip then
        player:onSkipBtnClick()
    elseif name == player.ButtonDef.Hu then
        player:onWinBtnClick()
    elseif name == player.ButtonDef.Pong then
        player:onPongBtnClick()
    elseif name == player.ButtonDef.Ting then
        player:onReadyHandBtnClick()
    elseif name == player.ButtonDef.Zhua then
        player:onFinalDrawBtnClick()
    end
end

--隐藏所有操作按钮
function PlayerView:hideOperationButtons()
    -- 先隐藏掉所有按钮
    self:showButton({})
    -- 隐藏根节点
    self.operationButtonsRoot.visible = false
end
------------------------------------
-- 设置金币数显示（目前是累计分数）
-----------------------------------
function PlayerView:setGold(_)
    -- if checkint(gold) < 0 then
    --     self.head.goldText1:Show()
    --     self.head.goldText:Hide()
    --     self.head.goldText1.text = tostring(gold)
    -- else
    --     self.head.goldText1:Hide()
    --     self.head.goldText:Show()
    --     self.head.goldText.text = tostring(gold)
    -- end
end

-------------------------------------------------
--保存头像周边内容节点
-------------------------------------------------
function PlayerView:initHeadView()
    local head = {}

    head.headBox = self.myView:GetChild("head")
    head.headBox.visible = false
    head.pos = head.headBox:GetChild("pos")
    -- ready状态指示
    head.readyIndicator = self.myView:GetChild("ready")
    head.readyIndicator.visible = false
    -- 听牌标志
    head.ting = self.myView:GetChild("ting")
    head.ting.visible = false
    -- 房间拥有者标志
    head.roomOwnerFlag = self.myView:GetChild("owner")
    head.roomOwnerFlag.visible = false

    --庄家标志
    head.bankerFlag = self.myView:GetChild("zhuang")
    head.bankerFlag.visible = false
    head.continuousBankerFlag = self.myView:GetChild("lianzhuang")
    head.continuousBankerFlag.visible = false

    head.HuaNode = self.myView:GetChild("hua")
    head.HuaNode.visible = false

    --更新庄家UI
    local updateBanker = function(isBanker, isContinue)
        if isBanker then
            if isContinue then
                head.bankerFlag.visible = false
                head.continuousBankerFlag.visible = true
            else
                head.bankerFlag.visible = true
                head.continuousBankerFlag.visible = false
            end
        else
            head.bankerFlag.visible = false
            head.continuousBankerFlag.visible = false
        end
    end
    head.onUpdateBankerFlag = updateBanker

    self.head = head
end

function PlayerView:initPlayerStatus()
    --重置位置
    local onReset = function(_)
        --  房间状态
        -- if roomstate == proto.mahjong.PlayerState.SRoomPlaying then
        -- self.infoGroup.localPosition = self.infoGroupPos.localPosition
        -- end
    end

    --起始
    local onStart = function()
        print("llwant ,test onstart ")
        self.head.readyIndicator.visible = false
        if self.checkReadyHandBtn then
            self.checkReadyHandBtn.visible = false
        end
    end

    --准备
    local onReady = function(roomstate)
        print("llwant ,test onReady ")
        self.head.readyIndicator.visible = true
        self:showOwner()
        onReset(roomstate)
    end

    --离线
    local onLeave = function(roomstate)
        print("llwant ,test onLeave ")
        self.head.readyIndicator.visible = false
        onReset(roomstate)
    end

    --正在玩
    local onPlaying = function(roomstate)
        print("llwant ,test onPlaying ")
        self.head.readyIndicator.visible = false
        self:showOwner()
        onReset(roomstate)
    end

    local status = {}
    status[mjproto.PlayerState.PSNone] = onStart
    status[mjproto.PlayerState.PSReady] = onReady
    status[mjproto.PlayerState.PSOffline] = onLeave
    status[mjproto.PlayerState.PSPlaying] = onPlaying
    self.onUpdateStatus = status
end

------------------------------------
-- 设置头像特殊效果是否显示（当前出牌者则显示）
-----------------------------------
function PlayerView:setHeadEffectBox(isShow)
    local x = self.head.pos.x
    local y = self.head.pos.y
    local ani = animation.play("animations/Effects_UI_touxiang.prefab", self.head.headBox, x, y, true)
    ani.setVisible(isShow)
end

------------------------------------
--从根节点上隐藏所有
------------------------------------
function PlayerView:hideAll()
end

------------------------------------
--新的一手牌开始，做一些清理后再开始
------------------------------------
function PlayerView:resetForNewHand()
    self:hideHands()
    self:hideFlowers()
    self:hideMelds()
    self:hideLights()
    self:clearDiscardable()
    self:hideDiscarded()

    self.head.ting.visible = false
    self:setHeadEffectBox(false)

    if self.viewChairID == 1 then
        self:hideOperationButtons()
    end
end

------------------------------------
--隐藏打出去的牌列表
------------------------------------
function PlayerView:hideDiscarded()
    if self.discards then
        for _, d in ipairs(self.discards) do
            d.visible = false
        end
    end
end

-------------------------------------
--隐藏摊开牌列表
-------------------------------------
function PlayerView:hideLights()
    if self.lights then
        for _, h in ipairs(self.lights) do
            h.visible = false
        end
    end
end

-------------------------------------
--隐藏手牌列表
-------------------------------------
function PlayerView:hideHands()
    if self.hands then
        for _, h in ipairs(self.hands) do
            h.visible = false
        end
    end
end

-------------------------------------
--隐藏面子牌组
-------------------------------------
function PlayerView:hideMelds()
    local mymeldTilesNode = self.myView:GetChild("melds")
    for i = 1, 4 do
        local mm = mymeldTilesNode:GetChild("myMeld" .. i)
        if mm then
            mymeldTilesNode:RemoveChild(mm, true)
        end
    end
end

------------------------------------------
--隐藏花牌列表
------------------------------------------
function PlayerView:hideFlowers()
    if self.flowers then
        for _, f in ipairs(self.flowers) do
            f.visible = false
        end
    end
    self.head.HuaNode.visible = false
end

------------------------------------------
--显示花牌，注意花牌需要是平放的
------------------------------------------
function PlayerView:showFlowers()
    local player = self.player
    local tilesFlower = player.tilesFlower
    local flowers = self.flowers

    --花牌个数
    local tileCount = #tilesFlower
    --花牌挂载点个数
    local dCount = #flowers

    self.head.HuaNode.visible = true

    --从那张牌开始挂载，由于tileCount可能大于dCount
    --因此，需要选择tilesDiscarded末尾的dCount个牌显示即可
    local begin = tileCount - dCount + 1
    if begin < 1 then
        begin = 1
    end

    --i计数器对应tilesFlower列表
    for i = begin, tileCount do
        local d = flowers[(i - 1) % dCount + 1]
        local tileID = tilesFlower[i]
        tileMounter:mountTileImage(d, tileID)
        d.visible = true
    end
end

------------------------------------------
--显示打出去的牌，明牌显示
------------------------------------------
function PlayerView:showDiscarded(newDiscard, waitDiscardReAction)
    local player = self.player
    local tilesDiscarded = player.tilesDiscarded

    --先隐藏所有的打出牌节点
    local discards = self.discards
    for _, d in ipairs(discards) do
        d.visible = false
    end

    --已经打出去的牌个数
    local tileCount = #tilesDiscarded
    --打出牌的挂载点个数
    local dCount = #discards
    --从那张牌开始挂载，由于tileCount可能大于dCount
    --因此，需要选择tilesDiscarded末尾的dCount个牌显示即可
    local begin = tileCount - dCount + 1
    if begin < 1 then
        begin = 1
    end

    --i计数器对应tilesDiscarded列表
    for i = begin, tileCount do
        local d = discards[(i - 1) % dCount + 1]
        local tileID = tilesDiscarded[i]
        tileMounter:mountTileImage(d, tileID)
        d.visible = true
    end

    --如果是新打出的牌，给加一个箭头
    if newDiscard then
        local d = discards[(tileCount - 1) % dCount + 1]
        player.room.roomView:setArrowByParent(d)

        --放大打出去的牌
        self:enlargeDiscarded(tilesDiscarded[tileCount], waitDiscardReAction)
    end
end

------------------------------------
--把打出的牌放大显示
------------------------------------
function PlayerView:enlargeDiscarded(discardTileId, waitDiscardReAction)
    local discardTips = self.discardTips
    local discardTipsTile = self.discardTipsTile
    -- local discardTipsYellow = self.discardTipsYellow
    tileMounter:mountTileImage(discardTipsTile, discardTileId)
    -- discardTipsTile.visible = true
    discardTips.visible = true
    if waitDiscardReAction then
        -- discardTipsYellow.visible = true
        self.player.waitDiscardReAction = true
    else
        -- discardTipsYellow.visible = false
        --ANITIME_DEFINE.OUTCARDTIPSHOWTIME --> 0.7
        self.myView:DelayRun(
            1,
            function()
                -- discardTipsTile.visible = false
                discardTips.visible = false
            end
        )
    end
end

---------------------------------------------
--显示对手玩家的手牌，对手玩家的手牌是暗牌显示
---------------------------------------------
function PlayerView:showHandsForOpponents()
    local player = self.player
    local tileCountInHand = player.tileCountInHand

    local meldCount = #player.melds
    if (3 * meldCount + tileCountInHand) > 13 then
        self.hands[14].visible = true
        tileCountInHand = tileCountInHand - 1
    end

    --melds面子牌组
    self:showMelds()

    for i = 1, tileCountInHand do
        self.hands[i].visible = true
    end
end

---------------------------------------------
--显示面子牌组
---------------------------------------------
function PlayerView:showMelds()
    local player = self.player
    local melds = player.melds
    local length = #melds
    local rm = MeldComponentPrefix[self.viewChairID]
    --摆放牌
    local mymeldTilesNode = self.myView:GetChild("melds")
    for i = 1, length do
        local mv = mymeldTilesNode:GetChild("meld" .. i)
        local mm = mymeldTilesNode:GetChild("myMeld" .. i)
        if mm then
            mymeldTilesNode:RemoveChild(mm, true)
        end
        --TODO:根据面子牌挂载牌的图片
        local meldData = melds[i]
        local resName = rm .. MeldComponentSuffix[meldData.meldType]
        local meldView = _ENV.thisMod:CreateUIObject("lobby_mahjong", resName)
        meldView.position = mv.position
        meldView.name = "myMeld" .. i
        mymeldTilesNode:AddChild(meldView)
        self:mountMeldImage(meldView, meldData)
    end
end

------------------------------------------
--显示面子牌组，暗杠需要特殊处理，如果是自己的暗杠，
--则明牌显示前3张，第4张暗牌显示（以便和明杠区分）
--如果是别人的暗杠，则全部暗牌显示
------------------------------------------
function PlayerView:mountMeldImage(meldView, msgMeld)
    local player = self.player
    local view = player.room:getPlayerViewByChairID(msgMeld.contributor)

    local t1 = meldView:GetChild("n1")
    local t2 = meldView:GetChild("n2")
    local t3 = meldView:GetChild("n3")
    local t4 = meldView:GetChild("n4")
    local meldType = msgMeld.meldType
    local mtProto = mjproto.MeldType
    if meldType == mtProto.enumMeldTypeSequence then
        local chowTile = t1
        if msgMeld.tile1 == msgMeld.chowTile then
            chowTile = t1
        elseif (msgMeld.tile1 + 1) == msgMeld.chowTile then
            chowTile = t2
        elseif (msgMeld.tile1 + 2) == msgMeld.chowTile then
            chowTile = t3
        end
        tileMounter:mountMeldEnableImage(t1, msgMeld.tile1, self.viewChairID)
        tileMounter:mountMeldEnableImage(t2, msgMeld.tile1 + 1, self.viewChairID)
        tileMounter:mountMeldEnableImage(t3, msgMeld.tile1 + 2, self.viewChairID)
        self:setMeldTileDirection(true, chowTile, view.viewChairID, self.viewChairID)
    elseif meldType == mtProto.enumMeldTypeTriplet then
        tileMounter:mountMeldEnableImage(t1, msgMeld.tile1, self.viewChairID, meldView.direction)
        tileMounter:mountMeldEnableImage(t2, msgMeld.tile1, self.viewChairID)
        tileMounter:mountMeldEnableImage(t3, msgMeld.tile1, self.viewChairID)
        self:setMeldTileDirection(false, t2, view.viewChairID, self.viewChairID)
    elseif meldType == mtProto.enumMeldTypeExposedKong or meldType == mtProto.enumMeldTypeTriplet2Kong then
        tileMounter:mountMeldEnableImage(t1, msgMeld.tile1, self.viewChairID)
        tileMounter:mountMeldEnableImage(t2, msgMeld.tile1, self.viewChairID)
        tileMounter:mountMeldEnableImage(t3, msgMeld.tile1, self.viewChairID)
        tileMounter:mountMeldEnableImage(t4, msgMeld.tile1, self.viewChairID)
        self:setMeldTileDirection(false, t4, view.viewChairID, self.viewChairID)
    end
end

--设置面子牌的方向
function PlayerView:setMeldTileDirection(ischi, tileObj, dir, viewChairID)
    if dir > 0 and viewChairID > 0 then
        local image = tileObj:GetChild("ts")
        if image then
            if ischi then
                image.url = "ui://dafeng/ts_chi"
            else
                local x = dir - viewChairID
                if x == 1 or x == -3 then
                    image.url = "ui://dafeng/ts_xia"
                elseif x == 2 or x == -2 then
                    image.url = "ui://dafeng/ts_dui"
                elseif x == 3 or x == -1 then
                    image.url = "ui://dafeng/ts_shang"
                end
            end
            image.visible = true
        end
    end
end

function PlayerView:mountConcealedKongTileImage(t, tileID)
    --local player = self.player
    --tileID == mjproto.mjproto.enumTid_MAX表示该牌需要暗牌显示
    if tileID == mjproto.TileID.enumTid_MAX then
        tileMounter:mountMeldDisableImage(t, tileID, self.viewChairID)
    else
        tileMounter:mountMeldEnableImage(t, tileID, self.viewChairID)
    end
end

function PlayerView:hideFlowerOnHandTail()
    self.hands[14].visible = false
end

function PlayerView:showFlowerOnHandTail(flower)
    self.hands[14].visible = true
    --local player = self.player
    if self.viewChairID == 1 then
        tileMounter:mountTileImage(self.hands[14], flower)
    end
end

---------------------------------------------
--为本人显示手牌，也即是1号playerView(prefab中的1号)
--@param wholeMove 是否整体移动
---------------------------------------------
function PlayerView:showHandsForMe(wholeMove)
    local player = self.player
    local tileshand = player.tilesHand
    local tileCountInHand = #tileshand
    local handsClickCtrls = self.handsClickCtrls
    --删除tileID
    --tileID主要是用于点击手牌时，知道该手牌对应那张牌ID
    for i = 1, 14 do
        handsClickCtrls[i].tileID = nil
    end

    --恢复所有牌的位置，由于点击手牌时会把手牌向上移动
    self:restoreHandPositionAndClickCount()

    local begin = 1
    local endd = tileCountInHand

    local meldCount = #player.melds
    if (3 * meldCount + tileCountInHand) > 13 then
        self.hands[14].visible = true
        if wholeMove then
            tileMounter:mountTileImage(self.hands[14], tileshand[1])
            handsClickCtrls[14].tileID = tileshand[1]
            begin = 2
        else
            tileMounter:mountTileImage(self.hands[14], tileshand[tileCountInHand])
            handsClickCtrls[14].tileID = tileshand[tileCountInHand]
            endd = tileCountInHand - 1
        end
    end

    --melds面子牌组
    self:showMelds()

    local j = 1
    for i = begin, endd do
        local h = self.hands[j]
        tileMounter:mountTileImage(h, tileshand[i])
        h.visible = true
        handsClickCtrls[j].tileID = tileshand[i]
        if self.player.isRichi then
            --如果是听牌状态下，则不再把牌弄回白色（让手牌一直是灰色的）
            -- 判断 handsClickCtrls[j].isDiscardable 是否为 true ,是的话 则不能 setGray
            self:setGray(h)
            handsClickCtrls[j].isGray = true
        end
        j = j + 1
    end
end

------------------------------------------
--把手牌摊开，包括对手的暗杠牌，用于一手牌结束时
--显示所有人的暗牌
------------------------------------------
function PlayerView:hand2Exposed(wholeMove)
    --不需要手牌显示了，全部摊开
    self:hideLights()

    --先显示所有melds面子牌组
    self:showMelds()

    local player = self.player
    local tileshand = player.tilesHand
    local tileCountInHand = #tileshand

    local begin = 1
    local endd = tileCountInHand

    local meldCount = #player.melds
    if (3 * meldCount + tileCountInHand) > 13 then
        local light = self.lights[14]
        if wholeMove then
            tileMounter:mountTileImage(light, tileshand[tileCountInHand])
            light.visible = true
            endd = tileCountInHand - 1
        else
            tileMounter:mountTileImage(light, tileshand[1])
            light.visible = true
            begin = 2
        end
    end

    local j = 1
    for i = begin, endd do
        local light = self.lights[j]
        tileMounter:mountTileImage(light, tileshand[i])
        light.visible = true
        j = j + 1
    end
end

------------------------------------------
--清除掉由于服务器发下来allowed actions而导致显示出来的view
--例如吃椪杠操作面板等等
------------------------------------------
function PlayerView:clearAllowedActionsView(discardAble)
    if not discardAble then
        --print("llwant, clear discardable.."..debug.traceback())
        self:clearDiscardable()
        --把听牌标志隐藏
        self:hideTing()
    end

    self:hideOperationButtons()
    --隐藏听牌详情界面
    self.player.room.roomView:hideTingDataView()
end

------------------------------------------
--处理玩家点击手牌按钮
--@param index 从1开始到14，表示手牌序号以及
--  摸牌（对应self.hands[14])
------------------------------------------
function PlayerView:onHandTileBtnClick(_, index)
    local handsClickCtrls = self.handsClickCtrls

    local player = self.player
    if player == nil then
        logger.debug("player == nil")
        return
    end

    local clickCtrl = handsClickCtrls[index]

    if not clickCtrl.isDiscardable then
        logger.debug("clickCtrl.isDiscardable ----")
        -- 不可以出牌
        --"本轮不能出与该牌组合的牌，请选择其他牌"
        if clickCtrl.isGray then
            logger.debug("clickCtrl.isGray ----")
            if not self.alreadyShowNonDiscardAbleTips then
                -- dfCompatibleAPI:showTip(
                --     "本轮不能出与该牌组合的牌，请选择其他牌",
                --     1,
                --     function()
                --         self.alreadyShowNonDiscardAbleTips = false
                --     end
                -- )
                self.alreadyShowNonDiscardAbleTips = true
            end
        end
        return
    end

    if clickCtrl.readyHandList ~= nil and #clickCtrl.readyHandList > 0 then
        --如果此牌可以听
        local tingP = {}
        for var = 1, #clickCtrl.readyHandList, 2 do
            table.insert(tingP, {Card = clickCtrl.readyHandList[var], Fan = 1, Num = clickCtrl.readyHandList[var + 1]})
        end
        self.player.room.roomView:showTingDataView(tingP)
    else
        self.player.room.roomView:hideTingDataView()
    end

    --播放选牌音效
    -- dfCompatibleAPI:soundPlay("effect/effect_xuanpai")

    clickCtrl.clickCount = clickCtrl.clickCount + 1
    if clickCtrl.clickCount == 1 then
        self:restoreHandPositionAndClickCount(index)
        self:moveHandUp(index)
    end

    if clickCtrl.clickCount == 2 then
        --判断可否出牌
        if player.waitSkip then
            self:restoreHandPositionAndClickCount()
            -- TODO :
            self.player.room.roomView:hideTingDataView()
        else
            player:onPlayerDiscardTile(clickCtrl.tileID)
            self:clearAllowedActionsView()
        end
    --player:onPlayerDiscardTile(clickCtrl.tileID)
    end
end

---------------------------------------------
--处理玩家点击左下角的“听”按钮
---------------------------------------------
function PlayerView:onCheckReadyHandBtnClick()
    local player = self.player
    local roomView = self.player.room.roomView
    local readyHandList = player.readyHandList
    if not roomView.listensObj.visible and readyHandList ~= nil and #readyHandList > 0 then
        -- local tingData = {}
        local tingP = {}
        for var = 1, #readyHandList, 2 do
            table.insert(tingP, {Card = readyHandList[var], Fan = 1, Num = readyHandList[var + 1]})
        end
        roomView:showTingDataView(tingP)
    else
        roomView:hideTingDataView()
    end
end
-------------------------------------------------
--拖动出牌事件
-------------------------------------------------
function PlayerView:onDrag(dragGo, index)
    local startPos = {x = dragGo.x, y = dragGo.y}
    local enable = false
    local clickCtrl
    -- local siblingIndex
    dragGo.draggable = true

    local x1 = dragGo.x - dragGo.width * 0.5
    local x2 = dragGo.x + dragGo.width * 0.5
    local y1 = dragGo.y - dragGo.height * 0.5
    local y2 = dragGo.y + dragGo.height * 0.5
    local rect = {x1, x2, y1, y2}

    --可否拖动
    local function dragable()
        --print("llwant, drag able")
        local player = self.player
        if player == nil then
            return false
        end

        local handsClickCtrls = self.handsClickCtrls
        clickCtrl = handsClickCtrls[index]
        return clickCtrl.isDiscardable and not player.waitSkip
    end

    --检测拖动范围时候合法
    local function pointIsInRect(x, y)
        if rect == nil then
            return false
        end

        if x > rect[1] and x < rect[2] and y > rect[3] and y < rect[4] then
            return true
        else
            return false
        end
    end

    --附加拖动效果
    local function attachEffect(_)
        -- self.dragEffect:SetParent(obj)
        -- self.dragEffect.localPosition = Vector3(0, 0, 0)
        -- self.dragEffect.visible = true
    end

    --去掉拖动效果
    local function detachEffect()
        -- self.dragEffect.visible = false
    end

    dragGo.onDragStart:Set(
        function(_)
            enable = dragable()
            --关闭拖动特效
            detachEffect()

            if not enable then
                return
            end
            self:restoreHandPositionAndClickCount(index)
            attachEffect(dragGo)
        end
    )

    dragGo.onDragMove:Set(
        function(_)
            if not enable then
                dragGo.x = startPos.x
                dragGo.y = startPos.y
                return
            end
            -- obj.position = pos
        end
    )

    dragGo.onDragEnd:Set(
        function(_)
            if not enable then
                return
            end

            --拖牌结束立即不显示
            dragGo.visible = false
            detachEffect()
            if pointIsInRect(dragGo.x, dragGo.y) then
                dragGo.visible = true
                dragGo.x = startPos.x
                dragGo.y = startPos.y
            else
                --重置打出的牌位置（TODO：需要测试当网络不好的情况下onPlayerDiscardTile发送数据失败，界面刷新情况）
                dragGo.visible = false
                dragGo.x = startPos.x
                dragGo.y = startPos.y
                --判断可否出牌
                if not self.player.waitSkip then
                    self.player:onPlayerDiscardTile(clickCtrl.tileID)
                    self:clearAllowedActionsView()
                end
            end
        end
    )
end

-------------------------------------------------
--还原所有手牌到它初始化时候的位置，并把clickCount重置为0
-------------------------------------------------
function PlayerView:restoreHandPositionAndClickCount(index)
    for i = 1, 14 do
        if i ~= index then
            local clickCtrl = self.handsClickCtrls[i]
            local originPos = self.handsOriginPos[i]
            local h = clickCtrl.h
            h.y = originPos.y
            clickCtrl.clickCount = 0
        end
    end
end

-------------------------------------------------
--隐藏听牌标志
-------------------------------------------------
function PlayerView:hideTing()
    for i = 1, 14 do
        local clickCtrl = self.handsClickCtrls[i]
        if clickCtrl ~= nil and clickCtrl.t ~= nil then
            clickCtrl.t.visible = false
        end
    end
end
-------------------------------------------------
--把手牌往上移动30的单位距离
-------------------------------------------------
function PlayerView:moveHandUp(index)
    local originPos = self.handsOriginPos[index]
    local h = self.handsClickCtrls[index].h
    h.y = originPos.y - 30
end

-------------------------------------------------
--让所有的手牌都不可以点击
-------------------------------------------------
function PlayerView:clearDiscardable()
    if self.player.isRichi then
        --如果是听牌状态下，则不再把牌弄回白色（让手牌一直是灰色的）
        return
    end
    for i = 1, 14 do
        local clickCtrl = self.handsClickCtrls[i]
        clickCtrl.isDiscardable = nil
        if clickCtrl.isGray then
            clickCtrl.isGray = nil
            self:clearGray(clickCtrl.h)
        end
    end
end

----------------------------------------------------------
--显示玩家头像
----------------------------------------------------------
function PlayerView:showHeadImg()
    self.head.headBox.visible = true
end

----------------------------------------------------------
--显示桌主
----------------------------------------------------------
function PlayerView:showOwner()
    local player = self.player
    self.head.roomOwnerFlag.visible = player:isMe()
end

----------------------------------------------------------
--播放补花效果，并等待结束
----------------------------------------------------------
function PlayerView:playDrawFlowerAnimation()
    self:playerOperationEffect("Effects_zi_buhua", true)
end

----------------------------------------------------------
--特效播放
----------------------------------------------------------
function PlayerView:playerOperationEffect(effectName, coYield)
    if coYield then
        animation.coplay("animations/" .. effectName .. ".prefab", self.myView, self.aniPos.x, self.aniPos.y)
    else
        animation.play("animations/" .. effectName .. ".prefab", self.myView, self.aniPos.x, self.aniPos.y)
    end
end

----------------------------------------------------------
--起手听特效播放
----------------------------------------------------------
function PlayerView:playReadyHandEffect()
    -- self:playerOperationEffect(dfConfig.EFF_DEFINE.SUB_ZI_TING)
end

--设置灰度
function PlayerView:setGray(_)
    -- if btn ~= nil then
    --     local hImg = btn:Find("hua")
    --     local imageA = btn:GetComponent("Image")
    --     local imageB = hImg:GetComponent("Image")
    --     imageA.color = Color(120 / 255, 122 / 255, 122 / 255, 1)
    --     imageB.color = Color(120 / 255, 122 / 255, 122 / 255, 1)
    -- end
end

--恢复灰度
function PlayerView:clearGray(_)
    -- if btn ~= nil then
    --     local hImg = btn:Find("hua")
    --     local imageA = btn:GetComponent("Image")
    --     local imageB = hImg:GetComponent("Image")
    --     imageA.color = Color(1, 1, 1, 1)
    --     imageB.color = Color(1, 1, 1, 1)
    -- end
end

return PlayerView
