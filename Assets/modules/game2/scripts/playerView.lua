--[[
    playerview对应玩家的视图，牌桌上有4个playerview
]]
--luacheck: no self
local PlayerView = {}

local mt = {__index = PlayerView}
--local fairy = require "lobby/lcore/fairygui"
local logger = require "lobby/lcore/logger"
local proto = require "scripts/proto/proto"
-- local animation = require "lobby/lcore/animations"
local tileMounter = require("scripts/tileImageMounter")

-----------------------------------------------
-- 新建一个player view
-- @param viewUnityNode 根据viewUnityNode获得playerView需要控制
-- 的所有节点
-----------------------------------------------
function PlayerView.new(viewUnityNode, viewChairID)
    local playerView = {}
    setmetatable(playerView, mt)
    -- 先找到牌相关的节点
    -- 现在的牌相关是在一个独立的prefab里面
    -- 这个prefab在roomView构造是已经加载进来
    -- 此处找到该节点
    -- 这里需要把player的chairID转换为游戏视图中的chairID，这是因为，无论当前玩家本人
    -- 的chair ID是多少，他都是居于正中下方，左手是上家，右手是下家，正中上方是对家
    -- 根据prefab中的位置，正中下方是Cards/1，左手是Cards/4，右手是Cards/2，正中上方是Cards/3
    -- local myTilesNode = viewUnityNode.transform:Find("Cards/" .. viewChairID)
    local view = viewUnityNode:GetChild("player" .. viewChairID)
    if (viewChairID == 1) then
        playerView.operationPanel = viewUnityNode:GetChild("operationPanel")
        playerView.meldOpsPanel = viewUnityNode:GetChild("meldOpsPanel")

        playerView:initOperationButtons()
        playerView:initMeldsPanel()
    end
    playerView.viewChairID = viewChairID
    playerView.viewUnityNode = viewUnityNode
    playerView.myView = view

    -- 先找到牌相关的节点
    -- 现在的牌相关是在一个独立的prefab里面
    -- 这个prefab在roomView构造是已经加载进来
    -- 此处找到该节点
    -- 这里需要把player的chairID转换为游戏视图中的chairID，这是因为，无论当前玩家本人
    -- 的chair ID是多少，他都是居于正中下方，左手是上家，右手是下家，正中上方是对家
    -- 根据prefab中的位置，正中下方是Cards/1，左手是Cards/4，右手是Cards/2，正中上方是Cards/3
    -- local myTilesNode = viewUnityNode.transform:Find("Cards/" .. viewChairID)
    -- playerView.tilesRoot = myTilesNode
    -- 打出的牌放大显示
    -- playerView.discardTips = viewUnityNode.transform:Find("OneOuts/" .. viewChairID)
    -- playerView.discardTipsTile = playerView.discardTips:Find("Card")
    -- playerView.discardTipsYellow = playerView.discardTips:Find("Card/Image")

    --特效提示位置
    -- playerView.operationTip = viewUnityNode.transform:Find("OpTips/" .. viewChairID)

    --拖动效果
    -- playerView.dragEffect = viewUnityNode.transform:Find("Effects_tuodong")

    --头像信息
    -- playerView.infoGroup = viewUnityNode.transform:Find("PlayInfoGroup/" .. viewChairID)
    -- playerView.infoGroupEmpty = viewUnityNode.transform:Find("PlayInfoGroup/" .. viewChairID .. "empty")
    -- playerView.infoGroupPos = viewUnityNode.transform:Find("PlayInfoGroup/" .. viewChairID .. "pos")

    -- 头像相关
    playerView:initHeadView()
    -- 玩家状态
    playerView:initPlayerStatus()

    -- 头像弹框
    -- playerView:initHeadPopup()

    return playerView
end

function PlayerView:initMeld()
    -- meld面子牌组，一共4组，最多也是4组，因为每一组3个牌，4组已经12个，剩下2张是雀头
    local meldsMap = {
        --自己，左中右
        {1, 4, 3, 2},
        {2, 1, 4, 3},
        {3, 2, 1, 4},
        {4, 3, 2, 1}
    }
    self.meldsMap = meldsMap

    -- local meldViews = {}
    -- local myMeldsNode = self.myView:GetChild("hands")
    -- self.meldsRoot = myMeldsNode
    -- for i = 1, 4 do
    -- local h = myMeldsNode.transform:Find(tostring(i))
    -- local meldView = {root = nil}
    -- -- meld内其他节点
    -- meld.t1 = h.transform:Find("1")
    -- meld.t2 = h.transform:Find("2")
    -- meld.t3 = h.transform:Find("3")
    -- meld.t4 = h.transform:Find("4")

    --位置
    -- local pos2 = myMeldsNode.transform:Find(tostring(i) .. "pos")
    -- meldView.localPosition = pos2.localPosition
    -- meldView.mountNode = pos2

    -- meldView.prefabItems = myMeldsNode.transform:Find("kong")
    -- meldView.prefabItems = {}
    -- local mm = meldsMap[viewChairID]
    -- --杠
    -- meldView.prefabItems[mm[1]] = myMeldsNode.transform:Find("kong")
    -- --左边
    -- meldView.prefabItems[mm[2]] = myMeldsNode.transform:Find("left")
    -- --右边
    -- meldView.prefabItems[mm[4]] = myMeldsNode.transform:Find("right")
    -- --对家
    -- meldView.prefabItems[mm[3]] = myMeldsNode.transform:Find("front")
    --     meldViews[i] = meldView
    -- end
    -- self.meldViews = meldViews
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
        end
        -- self:onDrag(h, i)
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
--面子牌选择面板
-------------------------------------------------
function PlayerView:initMeldsPanel()
    local meldMap = {}
    meldMap[1] = self.meldOpsPanel:GetChild("n1")
    meldMap[2] = self.meldOpsPanel:GetChild("n2")
    meldMap[3] = self.meldOpsPanel:GetChild("n3")
    meldMap[4] = self.meldOpsPanel:GetChild("bg")

    meldMap[1].visible = false
    meldMap[2].visible = false
    meldMap[3].visible = false

    self.multiOpsObj = meldMap
end
-------------------------------------------------
--保存操作按钮
-------------------------------------------------
function PlayerView:initOperationButtons()
    -- local operationButtonsRoot = viewUnityNode.transform:Find("TsBtnGroup/BgImg")
    self.operationButtonsRoot = self.operationPanel

    local pv = self

    self.skipBtn = self.operationPanel:GetChild("guoBtn")
    self.skipBtn.onClick:Set(
        function(obj)
            local player = pv.player
            player:onSkipBtnClick(obj)
        end
    )

    self.winBtn = self.operationPanel:GetChild("huBtn")
    self.winBtn.onClick:Set(
        function(obj)
            local player = pv.player
            player:onWinBtnClick(obj)
        end
    )
    --self:huBtnOrderAdd(self.winBtn)

    self.kongBtn = self.operationPanel:GetChild("gangBtn")
    self.kongBtn.onClick:Set(
        function(obj)
            local player = pv.player
            player:onKongBtnClick(obj)
        end
    )

    self.pongBtn = self.operationPanel:GetChild("pengBtn")
    self.pongBtn.onClick:Set(
        function(obj)
            local player = pv.player
            player:onPongBtnClick(obj)
        end
    )

    self.chowBtn = self.operationPanel:GetChild("chiBtn")
    self.chowBtn.onClick:Set(
        function(obj)
            local player = pv.player
            player:onChowBtnClick(obj)
        end
    )

    self.readyHandBtn = self.operationPanel:GetChild("tingBtn")
    self.readyHandBtn.onClick:Set(
        function(obj)
            local player = pv.player
            player:onReadyHandBtnClick(obj)
        end
    )

    -- self.finalDrawBtn = viewUnityNode:GetChild("TsBtnGroup/BgImg/ZhuaBtn")
    -- viewUnityNode:AddClick(
    --     self.finalDrawBtn,
    --     function(obj)
    --         local player = pv.player
    --         player:onFinalDrawBtnClick(obj)
    --     end
    -- )

    self.operationButtons = {self.skipBtn, self.winBtn, self.kongBtn, self.pongBtn, self.chowBtn, self.readyHandBtn}

    -- self.checkReadyHandBtn = viewUnityNode.transform:Find("Ting")
    -- viewUnityNode:AddClick(
    --     self.checkReadyHandBtn,
    --     function(obj)
    --         pv:onCheckReadyHandBtnClick(obj)
    --     end
    -- )

    self:hideOperationButtons()
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
--隐藏所有操作按钮
-------------------------------------------------
function PlayerView:hideOperationButtons()
    -- 先隐藏掉所有按钮
    local buttons = self.operationButtons
    for _, b in pairs(buttons) do
        b.visible = false
    end

    -- 隐藏根节点
    self.operationButtonsRoot.visible = false
end

-------------------------------------------------
--保存头像周边内容节点
-------------------------------------------------
function PlayerView:initHeadView()
    local head = {}

    head.headBox = self.myView:GetChild("head")
    head.headBox.visible = false
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
        -- head.root.visible = true
        -- head.stateOffline.visible = false
        -- self.infoGroupEmpty.visible = false
        self.head.readyIndicator.visible = false
        if self.checkReadyHandBtn ~= nil then
            self.checkReadyHandBtn.visible = false
        end
    end

    --准备
    local onReady = function(roomstate)
        print("llwant ,test onReady ")
        -- head.root.visible = true
        -- head.stateOffline.visible = false
        -- self.infoGroupEmpty.visible = false
        self.head.readyIndicator.visible = true
        self:showOwner()
        onReset(roomstate)
    end

    --离线
    local onLeave = function(roomstate)
        print("llwant ,test onLeave ")
        self.head.readyIndicator.visible = false
        -- self.infoGroupEmpty.visible = false
        -- head.stateOffline.visible = true
        onReset(roomstate)
    end

    --正在玩
    local onPlaying = function(roomstate)
        print("llwant ,test onPlaying ")
        self.head.readyIndicator.visible = false
        -- self.infoGroupEmpty.visible = false
        -- head.root.visible = true
        -- head.stateOffline.visible = false
        self:showOwner()
        onReset(roomstate)
    end

    local status = {}
    status[proto.mahjong.PlayerState.PSNone] = onStart
    status[proto.mahjong.PlayerState.PSReady] = onReady
    status[proto.mahjong.PlayerState.PSOffline] = onLeave
    status[proto.mahjong.PlayerState.PSPlaying] = onPlaying
    self.onUpdateStatus = status
end
------------------------------------
-- 设置头像特殊效果是否显示（当前出牌者则显示）
-----------------------------------
function PlayerView:setHeadEffectBox(isShow)
    if self.head.effectBox ~= nil then
        self.head.effectBox.visible = isShow
    end
end

------------------------------------
--从根节点上隐藏所有
------------------------------------
function PlayerView:hideAll()
    -- for _, v in ipairs(self.head) do
    --     v.visible = false
    -- end
    -- self.tilesRoot.visible = false
    -- self.headPopup.headInfobg.visible = false
end

------------------------------------
--新的一手牌开始，做一些清理后再开始
------------------------------------
function PlayerView:resetForNewHand()
    self:hideHands()
    self:hideFlowers()
    self:hideLights()
    self:clearDiscardable()
    self:hideDiscarded()

    self.head.ting.visible = false
    self:setHeadEffectBox(false)

    if self.viewChairID == 1 then
        self:hideOperationButtons()
    end

    --面子牌组需要重置
    -- for _, m in ipairs(self.meldViews) do
    --     if m.root then
    --         --m.root.visible = false
    --         tool:DestroyAllChilds(m.mountNode)
    --         m.root = nil

    --         --清理加杠遗留
    --         if m.alreadyUsedKongPrefb then
    --             m.alreadyUsedKongPrefb = false
    --         end
    --     end
    -- end
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
--其实是把整行都隐藏了
-------------------------------------
function PlayerView:hideHands()
    if self.hands then
        for _, h in ipairs(self.hands) do
            h.visible = false
        end
    end
    --TODO: 取消所有听牌、黄色遮罩等等
    -- self.na.visible = false

    --面子牌组也隐藏
    -- for _, m in ipairs(self.meldViews) do
    --     if m.root then
    --         m.root.visible = false
    --     end
    -- end
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

    -- if tileCount > 0 then
    --self.head.HuaNode.visible = true
    -- self.head.HuaCountText.text = tostring(tileCount)
    -- else
    --self.head.HuaNode.visible = false
    -- self.head.HuaCountText.text = "0"
    -- end
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
        local d = discards[tileCount % dCount]
        player.room.roomView:setArrowByParent(d)

        --放大打出去的牌
        self:enlargeDiscarded(tilesDiscarded[tileCount], waitDiscardReAction)
    end
end

------------------------------------
--把打出的牌放大显示
------------------------------------
function PlayerView:enlargeDiscarded(_, _)
    -- local discardTips = self.discardTips
    -- local discardTipsTile = self.discardTipsTile
    -- local discardTipsYellow = self.discardTipsYellow
    -- tileMounter:mountTileImage(discardTipsTile, discardTileId)
    -- discardTipsTile.visible = true
    -- discardTips.visible = true
    -- if waitDiscardReAction then
    --     self.player.waitDiscardReAction = true
    --     discardTipsYellow.visible = true
    -- else
    --     discardTipsYellow.visible = false
    --     --ANITIME_DEFINE.OUTCARDTIPSHOWTIME --> 0.7
    --     self.viewUnityNode:DelayRun(
    --         0.1,
    --         function()
    --             discardTipsTile.visible = false
    --             discardTips.visible = false
    --         end
    --     )
    -- end
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
    local rm = ""
    if self.viewChairID == 1 then
        rm = "mahjong_mine_meld_"
    elseif self.viewChairID == 2 then
        rm = "mahjong_right_meld_"
    elseif self.viewChairID == 3 then
        rm = "mahjong_dui_meld_"
    elseif self.viewChairID == 4 then
        rm = "mahjong_left_meld_"
    end
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
        local resName = ""
        if meldData.meldType == proto.mahjong.MeldType.enumMeldTypeTriplet2Kong then
            -- 如果是加杠，需要检查之前的碰的牌组是否存在，是的话需要删除
            resName = rm .. "gang1"
        elseif meldData.meldType == proto.mahjong.MeldType.enumMeldTypeExposedKong then
            --明杠
            resName = rm .. "gang1"
        elseif meldData.meldType == proto.mahjong.MeldType.enumMeldTypeConcealedKong then
            --暗杠
            resName = rm .. "gang2"
        elseif meldData.meldType == proto.mahjong.MeldType.enumMeldTypeSequence then
            --吃
            resName = rm .. "chipeng"
        elseif meldData.meldType == proto.mahjong.MeldType.enumMeldTypeTriplet then
            --碰
            resName = rm .. "chipeng"
        end
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
    -- local player = self.player
    -- local view = player.room:getPlayerViewByChairID(msgMeld.contributor)
    -- local mm = self.meldsMap[self.viewChairID]
    -- local direction = mm[view.viewChairID]
    -- -- self.viewChairID 吃碰杠者
    -- -- view.viewChairID 被吃碰杠者
    -- local ischi = false
    local mjproto = proto.mahjong.MeldType
    local t1 = meldView:GetChild("n1")
    local t2 = meldView:GetChild("n2")
    local t3 = meldView:GetChild("n3")
    local t4 = meldView:GetChild("n4")
    local meldType = msgMeld.meldType
    if meldType == mjproto.enumMeldTypeSequence then
        tileMounter:mountMeldEnableImage(t1, msgMeld.tile1, self.viewChairID)
        tileMounter:mountMeldEnableImage(t2, msgMeld.tile1 + 1, self.viewChairID)
        tileMounter:mountMeldEnableImage(t3, msgMeld.tile1 + 2, self.viewChairID)
    elseif meldType == mjproto.enumMeldTypeTriplet then
        tileMounter:mountMeldEnableImage(t1, msgMeld.tile1, self.viewChairID, meldView.direction)
        tileMounter:mountMeldEnableImage(t2, msgMeld.tile1, self.viewChairID)
        tileMounter:mountMeldEnableImage(t3, msgMeld.tile1, self.viewChairID)
    elseif meldType == mjproto.enumMeldTypeExposedKong or meldType == mjproto.enumMeldTypeTriplet2Kong then
        tileMounter:mountMeldEnableImage(t1, msgMeld.tile1, self.viewChairID)
        tileMounter:mountMeldEnableImage(t2, msgMeld.tile1, self.viewChairID)
        tileMounter:mountMeldEnableImage(t3, msgMeld.tile1, self.viewChairID)
        tileMounter:mountMeldEnableImage(t4, msgMeld.tile1, self.viewChairID)
    end
end

--单独用于结算界面的面子牌组显示
function PlayerView:mountResultMeldImage(_, _)
    -- local player = self.player
    -- local view = player.room:getPlayerViewByChairID(msgMeld.contributor)
    -- -- self.viewChairID 吃碰杠者
    -- -- view.viewChairID 被吃碰杠者
    -- local mm = self.meldsMap[self.viewChairID]
    -- local direction = mm[view.viewChairID]
    -- local ischi = false
    -- if msgMeld.meldType == mjproto.enumMeldTypeSequence then
    --     --对于吃牌组，第一个牌为被吃的牌，其他是玩家自身的牌
    --     tileMounter:mountTileImage(meldView.t1, msgMeld.chowTile)
    --     local chowTile = meldView.t1
    --     if msgMeld.tile1 == msgMeld.chowTile then
    --         chowTile = meldView.t1
    --     elseif (msgMeld.tile1 + 1) == msgMeld.chowTile then
    --         chowTile = meldView.t2
    --     elseif (msgMeld.tile1 + 2) == msgMeld.chowTile then
    --         chowTile = meldView.t3
    --     end
    --     local ischi = true
    --     tileMounter:mountMeldEnableImage(meldView.t1, msgMeld.tile1, self.viewChairID)
    --     tileMounter:mountMeldEnableImage(meldView.t2, msgMeld.tile1 + 1, self.viewChairID)
    --     tileMounter:mountMeldEnableImage(meldView.t3, msgMeld.tile1 + 2, self.viewChairID)
    --     self:setMeldTileDirection(ischi, chowTile, view.viewChairID, self.viewChairID)
    --     meldView.t4.visible = false
    -- elseif msgMeld.meldType == mjproto.enumMeldTypeTriplet then
    --     tileMounter:mountTileImage(meldView.t1, msgMeld.tile1)
    --     tileMounter:mountTileImage(meldView.t2, msgMeld.tile1)
    --     tileMounter:mountTileImage(meldView.t3, msgMeld.tile1)
    --     self:setMeldTileDirection(ischi, meldView.t2, view.viewChairID, self.viewChairID)
    --     meldView.t4.visible = false
    -- elseif msgMeld.meldType == mjproto.enumMeldTypeExposedKong or msgMeld.meldType
    -- == mjproto.enumMeldTypeTriplet2Kong then
    --     tileMounter:mountTileImage(meldView.t1, msgMeld.tile1)
    --     tileMounter:mountTileImage(meldView.t2, msgMeld.tile1)
    --     tileMounter:mountTileImage(meldView.t3, msgMeld.tile1)
    --     tileMounter:mountTileImage(meldView.t4, msgMeld.tile1)
    --     self:setMeldTileDirection(ischi, meldView.t4, view.viewChairID, self.viewChairID)
    --     meldView.t4.visible = true
    -- elseif msgMeld.meldType == mjproto.enumMeldTypeConcealedKong then
    --     tileMounter:mountMeldDisableImage(meldView.t1, msgMeld.tile1, self.viewChairID)
    --     tileMounter:mountMeldDisableImage(meldView.t2, msgMeld.tile1, self.viewChairID)
    --     tileMounter:mountMeldDisableImage(meldView.t3, msgMeld.tile1, self.viewChairID)
    --     --使用对家的资源
    --     tileMounter:mountMeldEnableImage(meldView.t4, msgMeld.tile1, 3)
    --     meldView.t4.visible = true
    -- end
end

function PlayerView:mountConcealedKongTileImage(t, tileID)
    --local player = self.player
    --tileID == mjproto.mjproto.enumTid_MAX表示该牌需要暗牌显示
    if tileID == proto.mahjong.TileID.enumTid_MAX then
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

    --TODO:有必要提取一个clearXXX函数
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
            --print("llwant, gray it")
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
    --playerView.lights
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

    --self.checkReadyHandBtn.visible = false
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
        -- local tingData = {}
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
    if not roomView.ListensObj.activeSelf and readyHandList ~= nil and #readyHandList > 0 then
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
    local rect
    local startPos
    local enable
    local clickCtrl
    local siblingIndex

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
    local function pointIsInRect(pos)
        if rect == nil then
            return false
        end

        if pos.x > rect[1] and pos.x < rect[2] and pos.y > rect[3] and pos.y < rect[4] then
            return true
        else
            return false
        end
    end

    --附加拖动效果
    local function attachEffect(obj)
        self.dragEffect:SetParent(obj)
        -- self.dragEffect.localPosition = Vector3(0, 0, 0)
        self.dragEffect.visible = true
    end

    --去掉拖动效果
    local function detachEffect()
        self.dragEffect.visible = false
    end

    dragGo.onBeginDrag = function(obj, _)
        --print("llwant, darg onbegindrag")
        if not enable then
            return
        end

        self:restoreHandPositionAndClickCount(index)
        attachEffect(obj)
    end

    dragGo.onDown = function(_, _)
        enable = dragable()
        --关闭拖动特效
        detachEffect()

        if not enable then
            startPos = dragGo.localPosition
            return
        end
        siblingIndex = dragGo:GetSiblingIndex()

        --print("llwant, drag ondown")
        local x1 = dragGo.localPosition.x - dragGo.sizeDelta.x * 0.5
        local x2 = dragGo.localPosition.x + dragGo.sizeDelta.x * 0.5
        local y1 = dragGo.localPosition.y - dragGo.sizeDelta.y * 0.5
        local y2 = dragGo.localPosition.y + dragGo.sizeDelta.y * 0.5
        rect = {x1, x2, y1, y2}

        startPos = dragGo.localPosition
        dragGo:SetAsLastSibling()
    end

    dragGo.onMove = function(_, _, _)
        if not enable then
            dragGo.localPosition = startPos
            return
        end
        -- obj.position = pos
    end

    dragGo.onEndDrag = function(_, _)
        if not enable then
            return
        end

        --拖牌结束立即不显示
        dragGo.visible = false

        dragGo:SetSiblingIndex(siblingIndex)
        --print("llwant, darg onenddrag")
        detachEffect()
        if pointIsInRect(dragGo.localPosition) then
            dragGo.visible = true
            dragGo.localPosition = startPos
        else
            --重置打出的牌位置（TODO：需要测试当网络不好的情况下onPlayerDiscardTile发送数据失败，界面刷新情况）
            dragGo.visible = false
            dragGo.localPosition = startPos

            --判断可否出牌
            if not self.player.waitSkip then
                self.player:onPlayerDiscardTile(clickCtrl.tileID)
                self:clearAllowedActionsView()
            end
        end
    end
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
    -- if self.head == nil then
    --     logger.debug("showImg, self.head == nil")
    --     return
    -- end
    -- if self.head.headImg == nil then
    --     logger.debug("showHeadImg, self.head.headImg == nil")
    --     return
    -- end
    -- local player = self.player
    -- if player == nil then
    --     logger.debug("showHeadImg, player == nil")
    --     return
    -- end
    -- if player.sex == 1 then
    --     self.head.headImg.sprite = dfCompatibleAPI:loadDynPic("playerIcon/boy_head_img")
    -- else
    --     self.head.headImg.sprite = dfCompatibleAPI:loadDynPic("playerIcon/girl_head_img")
    -- end
    -- if player.headIconURI and player.headIconURI ~= "" then
    --     print("showHeadImg player.headIconURI = " .. player.headIconURI)
    --     tool:SetUrlImage(self.head.headImg.transform, player.headIconURI)
    -- else
    --     logger.debug("showHeadIcon,  player.headIconURI == nil")
    -- end
    -- local boxImg = self.head.headBox.transform:GetComponent("Image")
    -- boxImg.sprite = self.head.defaultHeadBox.sprite
    -- boxImg:SetNativeSize()
    -- self.head.headBox.transform.localScale = Vector3(1, 1, 1)
    -- self.head.effectBox.transform.localScale = Vector3(1, 1, 1)
    -- if self.head.headBox ~= nil and player.avatarID ~= nil and player.avatarID ~= 0 then
    --     local imgPath = string.format("Component/CommonComponent/Bundle/image/bk_%d.png", player.avatarID)
    --     self.head.headBox.transform:SetImage(imgPath)
    --     self.head.headBox.transform:GetComponent("Image"):SetNativeSize()
    --     self.head.headBox.transform.localScale = Vector3(0.8, 0.8, 0.8)
    --     self.head.effectBox.transform.localScale = Vector3(1.25, 1.25, 1.25)
    -- end
end

----------------------------------------------------------
--如果头像不存在则从微信服务器拉取
----------------------------------------------------------
function PlayerView:getPartnerWeixinIcon(_, _, _)
    -- self.playersIcon = self.playersIcon or {}
    -- self.playersIcon[iconUrl] = self.playersIcon[iconUrl] or {}
    -- local icon = self.playersIcon[iconUrl]
    -- if icon.tex ~= nil then
    --     compCallback(icon.tex)
    -- else
    --     if icon.started then
    --         return
    --     end
    --     icon.started = true
    --     local www =
    --         HttpGet(
    --         iconUrl,
    --         function(www)
    --             local tex = www.texture
    --             icon.tex = tex
    --             compCallback(tex)
    --         end,
    --         function(error)
    --             if failCallback then
    --                 failCallback(error)
    --             end
    --         end
    --     )
    --     if www and not www.error then
    --         icon.started = false
    --     end
    -- end
end

----------------------------------------------------------
--显示桌主
----------------------------------------------------------
function PlayerView:showOwner()
    local player = self.player
    self.head.roomOwnerFlag.visible = player:isMe()
end

----------------------------------------------------------
--动画播放，吃
----------------------------------------------------------
function PlayerView:playChowResultAnimation()
    -- local player = self.player
    -- --播放特效
    -- self:playerOperationEffect(dfConfig.EFF_DEFINE.SUB_ZI_CHI)
end

----------------------------------------------------------
--动画播放，碰
----------------------------------------------------------
function PlayerView:playPongResultAnimation()
    -- local player = self.player
    -- --播放特效
    -- self:playerOperationEffect(dfConfig.EFF_DEFINE.SUB_ZI_PENG)
end

----------------------------------------------------------
--动画播放，明杠
----------------------------------------------------------
function PlayerView:playExposedKongResultAnimation()
    -- local player = self.player
    -- --播放特效
    -- self:playerOperationEffect(dfConfig.EFF_DEFINE.SUB_ZI_GANG)
end

----------------------------------------------------------
--动画播放，暗杠
----------------------------------------------------------
function PlayerView:playConcealedKongResultAnimation()
    -- local player = self.player
    -- --播放特效
    -- self:playerOperationEffect(dfConfig.EFF_DEFINE.SUB_ZI_GANG)
end

----------------------------------------------------------
--动画播放，加杠（效果表现和明杠一样）
----------------------------------------------------------
function PlayerView:playTriplet2KongResultAnimation()
    self:playExposedKongResultAnimation()
end

----------------------------------------------------------
--抓牌
----------------------------------------------------------
function PlayerView:playZhuaPaiAnimation()
    -- self:playerOperationEffect(dfConfig.EFF_DEFINE.SUB_ZI_ZHUA)
end

----------------------------------------------------------
--播放补花效果，并等待结束
----------------------------------------------------------
function PlayerView:playDrawFlowerAnimation()
    -- local waitCo = coroutine.running()
    -- local effectObj = Animator.Play(dfConfig.PATH.EFFECTS .
    --. dfConfig.EFF_DEFINE.SUB_ZI_BUHUA .. ".prefab", self.viewUnityNode.order)
    -- effectObj:SetParent(self.operationTip)
    -- effectObj.localPosition = Vector3(0, 0, 0)
    -- self.player:playSound("operate", "hua")
    -- self.viewUnityNode:DelayRun(
    --     0.8,
    --     function()
    --         --修改 补花时长    1.5 --> 0.8
    --         local flag, msg = coroutine.resume(waitCo)
    --         if not flag then
    --             logError(msg)
    --             return
    --         end
    --     end
    -- )
    -- coroutine.yield()
end

----------------------------------------------------------
--特效播放
----------------------------------------------------------
function PlayerView:playerOperationEffect(_, _)
    -- local effectObj = Animator.Play(dfConfig.PATH.EFFECTS .. effectName .. ".prefab", self.viewUnityNode.order)
    -- effectObj:SetParent(self.operationTip)
    -- effectObj.localPosition = Vector3(0, 0, 0)
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

----------------------------------------------------------
--头像动画播放
----------------------------------------------------------
function PlayerView:playInfoGroupAnimation()
    -- local targetPos = self.infoGroupPos.localPosition
    -- actionMgr:MoveTo(self.infoGroup, targetPos, 1, function()
    --     --不等待动画完成
    -- end)
end

--设置面子牌的方向
function PlayerView:setMeldTileDirection(_, _, _, _)
    -- print("llwant,PlayerView:setMeldTileDirection:viewChairID is " .. viewChairID)
    -- print("llwant,PlayerView:setMeldTileDirection:dir is : " .. dir)
    -- if dir > 0 and viewChairID > 0 then
    --     local image = tileObj.transform:Find("direction")
    --     if image then
    --         if ischi then
    --             image:SetImage("GameModule/DaFengMaJiang/_AssetsBundleRes/image/ts_chi.png")
    --         else
    --             if viewChairID == 1 then
    --                 if dir == 1 then
    --                 elseif dir == 2 then
    --                     image:SetImage("GameModule/DaFengMaJiang/_AssetsBundleRes/image/ts_xia.png")
    --                 elseif dir == 3 then
    --                     image:SetImage("GameModule/DaFengMaJiang/_AssetsBundleRes/image/ts_dui.png")
    --                 elseif dir == 4 then
    --                     image:SetImage("GameModule/DaFengMaJiang/_AssetsBundleRes/image/ts_shang.png")
    --                 end
    --             elseif viewChairID == 2 then
    --                 if dir == 1 then
    --                     image:SetImage("GameModule/DaFengMaJiang/_AssetsBundleRes/image/ts_shang.png")
    --                 elseif dir == 2 then
    --                 elseif dir == 3 then
    --                     image:SetImage("GameModule/DaFengMaJiang/_AssetsBundleRes/image/ts_xia.png")
    --                 elseif dir == 4 then
    --                     image:SetImage("GameModule/DaFengMaJiang/_AssetsBundleRes/image/ts_dui.png")
    --                 end
    --             elseif viewChairID == 3 then
    --                 if dir == 1 then
    --                     image:SetImage("GameModule/DaFengMaJiang/_AssetsBundleRes/image/ts_dui.png")
    --                 elseif dir == 2 then
    --                     image:SetImage("GameModule/DaFengMaJiang/_AssetsBundleRes/image/ts_shang.png")
    --                 elseif dir == 3 then
    --                 elseif dir == 4 then
    --                     image:SetImage("GameModule/DaFengMaJiang/_AssetsBundleRes/image/ts_xia.png")
    --                 end
    --             else
    --                 if dir == 1 then
    --                     image:SetImage("GameModule/DaFengMaJiang/_AssetsBundleRes/image/ts_xia.png")
    --                 elseif dir == 2 then
    --                     image:SetImage("GameModule/DaFengMaJiang/_AssetsBundleRes/image/ts_dui.png")
    --                 elseif dir == 3 then
    --                     image:SetImage("GameModule/DaFengMaJiang/_AssetsBundleRes/image/ts_shang.png")
    --                 elseif dir == 4 then
    --                 end
    --             end
    --         end
    --         image.visible = true
    --     end
    -- end
end

return PlayerView
