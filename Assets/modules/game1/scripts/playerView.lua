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

-----------------------------------------------
-- 新建一个player view
-- @param viewUnityNode 根据viewUnityNode获得playerView需要控制
-- 的所有节点
-----------------------------------------------
function PlayerView.new(viewUnityNode, viewChairID)
    local playerView = {}
    setmetatable(playerView, mt)
    -- 这里需要把player的chairID转换为游戏视图中的chairID，这是因为，无论当前玩家本人
    -- 的chair ID是多少，他都是居于正中下方，左手是上家，右手是下家，正中上方是对家
    -- 根据prefab中的位置，正中下方是Cards/1，左手是Cards/4，右手是Cards/2，正中上方是Cards/3
    -- local myTilesNode = viewUnityNode.transform:Find("Cards/" .. viewChairID)
    local view = nil
    if (viewChairID == 1) then
        view = viewUnityNode:GetChild("playerMine")
        playerView.operationPanel = viewUnityNode:GetChild("operationPanel")
        playerView:initOperationButtons()
    elseif (viewChairID == 2) then
        view = viewUnityNode:GetChild("playerRight")
    elseif (viewChairID == 3) then
        view = viewUnityNode:GetChild("playerLeft")
    end
    playerView.viewChairID = viewChairID
    playerView.viewUnityNode = viewUnityNode
    playerView.myView = view
    playerView.aniPos = view:GetChild("aniPos")
    -- -- self.texiaoPos = myTilesNode.transform:Find("texiaoPos") --特效的位置
    -- local operationPanel = view:GetChild("n31")
    -- 头像相关
    playerView:initHeadView(view)
    -- 玩家状态
    playerView:initPlayerStatus()
    -- -- 滑动拖牌
    -- viewUnityNode:AddDrag(
    --     myHandTilesNode,
    --     function(cardObj, data)
    --         playerView:OnItemDrag(cardObj, data)
    --     end
    -- )
    -- viewUnityNode:AddBeginDrag(
    --     myHandTilesNode,
    --     function(cardObj, data)
    --         playerView:OnItemBeginDrag(cardObj, data)
    --     end
    -- )
    -- viewUnityNode:AddDragEnd(
    --     myHandTilesNode,
    --     function(cardObj, data)
    --         playerView:OnItemDragEnd(cardObj, data)
    --     end
    -- )

    return playerView
end

function PlayerView:initCardLists()
    -- 手牌
    self:initHands()
    -- 出牌列表
    self:initDiscards()
    -- 明牌列表
    self:initLights()
end

function PlayerView:initLights()
    if self.lights then
        return
    end
    local view = self.myView
    -- 手牌列表
    local lights = {}
    if (self.viewChairID ~= 1) then
        local tilesNode = view:GetChild("lights")
        for i = 1, 16 do
            local cname = "n" .. i
            local go = tilesNode:GetChild(cname)
            if go ~= nil then
                local card = _ENV.thisMod:CreateUIObject("runfast", "desk_poker_number")
                card.scale = go.scale
                card.position = go.position
                tilesNode:AddChild(card)
                card.visible = false
                lights[i] = card
            else
                logger.error("can not found child:", cname)
            end
        end

        self.lights = lights
    end
end

function PlayerView:initHands()
    if self.hands then
        return
    end
    local view = self.myView
    -- 手牌列表
    local hands = {}
    local handsOriginPos = {}
    local handsClickCtrls = {}
    if (self.viewChairID == 1) then
        local myHandTilesNode = view:GetChild("hands")
        for i = 1, 16 do
            local cname = "n" .. i
            local go = myHandTilesNode:GetChild(cname)
            if go ~= nil then
                local card = _ENV.thisMod:CreateUIObject("runfast", "desk_poker_number")
                card.position = go.position
                myHandTilesNode:AddChild(card)
                local btn = card:GetChild("n0")
                btn.onClick:Set(
                    function()
                        self:onHandTileBtnClick(i)
                    end
                )
                card.name = tostring(i) --把手牌按钮对应的序号记忆，以便点击时可以识别
                card.visible = false
                hands[i] = card
                local pos = {}
                pos.x = card.x
                pos.y = card.y
                table.insert(handsOriginPos, pos)
                table.insert(handsClickCtrls, {clickCount = 0, h = card})
            else
                logger.error("can not found child:", cname)
            end
        end
    else
        --用于显示手牌数量
        self.handsNumber = view:GetChild("handsNum")
        hands[1] = view:GetChild("hands")
    end
    self.hands = hands
    self.handsOriginPos = handsOriginPos --记忆原始的手牌位置，以便点击手牌时可以往上弹起以及恢复
    self.handsClickCtrls = handsClickCtrls -- 手牌点击时控制数据结构
end
function PlayerView:initDiscards()
    if self.discards then
        return
    end
    local view = self.myView
    -- 打出的牌列表
    local discards = {}
    local myHandTilesNode = view:GetChild("discards")
    for i = 1, 16 do
        local cname = "n" .. i
        local go = myHandTilesNode:GetChild(cname)
        if go ~= nil then
            local card = _ENV.thisMod:CreateUIObject("runfast", "desk_poker_number")
            card.scale = go.scale
            card.position = go.position
            myHandTilesNode:AddChild(card)
            card.visible = false
            discards[i] = card
        else
            logger.error("can not found child:", cname)
        end
    end
    self.discards = discards
end
-------------------------------------------------
--保存操作按钮
-------------------------------------------------
function PlayerView:initOperationButtons()
    local view = self.operationPanel
    local pv = self
    self.skipBtn = view:GetChild("pass")
    self.tipBtn = view:GetChild("tip")
    self.discardBtn = view:GetChild("discard")
    self.skipBtn.onClick:Set(
        function(obj)
            local player = pv.player
            player:onSkipBtnClick(false, obj)
        end
    )
    self.tipBtn.onClick:Set(
        function(obj)
            local player = pv.player
            player:onTipBtnClick(false, obj)
        end
    )
    self.discardBtn.onClick:Set(
        function(obj)
            local player = pv.player
            player:onDiscardBtnClick(false, obj)
        end
    )
    self.operationButtons = {
        self.skipBtn,
        self.tipBtn,
        self.discardBtn
    }
    self:hideOperationButtons()
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
end

-------------------------------------------------
--保存头像周边内容节点
-------------------------------------------------
function PlayerView:initHeadView(view)
    local head = {}
    local headImg = view:GetChild("head")
    headImg.visible = false

    head.scoreBg = view:GetChild("score")
    head.readyIndicator = view:GetChild("ready")
    head.scoreText = view:GetChild("scoreText")
    head.countDownImage = view:GetChild("count")
    head.countDownText = view:GetChild("countDown")
    head.roomOwner = view:GetChild("roomOwner")

    head.headImg = headImg

    self.head = head
end

function PlayerView:initPlayerStatus()
    --起始
    local onStart = function()
        logger.debug("llwant ,test onstart ")
        self.head.readyIndicator.visible = false
    end

    --准备
    local onReady = function()
        logger.debug("llwant ,test onReady ")
        self.head.readyIndicator.visible = true
    end

    --离线
    local onLeave = function()
        logger.debug("llwant ,test onLeave ")
        self.head.readyIndicator.visible = false
    end

    --正在玩
    local onPlaying = function()
        logger.debug("llwant ,test onPlaying ")
        self.head.readyIndicator.visible = false
    end

    ----玩家状态
    local status = {}
    status[proto.pokerface.PlayerState.PSNone] = onStart
    status[proto.pokerface.PlayerState.PSReady] = onReady
    status[proto.pokerface.PlayerState.PSOffline] = onLeave
    status[proto.pokerface.PlayerState.PSPlaying] = onPlaying
    self.onUpdateStatus = status
end

------------------------------------
-- 设置头像特殊效果是否显示（当前出牌者则显示）
-----------------------------------
function PlayerView:setHeadEffectBox(isShow)
    self.head.countDownImage.visible = isShow
    self.head.countDownText.visible = isShow
    if isShow then
        self.leftTime = 20
        --起定时器
        self.viewUnityNode:StartTimer(
            "playerCountDown",
            1,
            0,
            function()
                self.leftTime = self.leftTime - 1
                self.head.countDownText.text = self.leftTime
                if self.leftTime <= 0 then
                    self.viewUnityNode:StopTimer("playerCountDown")
                end
            end,
            self.leftTime
        )
    else
        --清理定时器
        self.viewUnityNode:StopTimer("playerCountDown")
    end
    -- if self.head.effectBox ~= nil then
    --     self.head.effectBox:SetActive(isShow)
    -- end
end

------------------------------------
--从根节点上隐藏所有
------------------------------------
function PlayerView:hideAll()
    for _, v in ipairs(self.head) do
        v.visible = false
    end
    if self.handsNumber then
        self.handsNumber.text = ""
    end
    self:hideHands()
    self:hideLights()
    self:hideDiscarded()
end

------------------------------------
--新的一手牌开始，做一些清理后再开始
------------------------------------
function PlayerView:resetForNewHand()
    self:hideHands()
    self:hideLights()
    self:hideDiscarded()
    --特效列表
    --self:cleanEffectObjLists()
    self:setHeadEffectBox(false)
    self:hideGaoJing()
    --这里还要删除特效
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
--其实是把整行都隐藏了
-------------------------------------
function PlayerView:hideHands()
    if self.hands then
        for _, h in ipairs(self.hands) do
            h.visible = false
        end
    end
    if self.handsNumber then
        self.handsNumber.visible = false
    end
end

------------------------------------------
--显示打出去的牌，明牌显示
------------------------------------------
function PlayerView:showDiscarded(tilesDiscarded)
    --先隐藏所有的打出牌节点
    self:hideDiscarded()
    local discards = self.discards

    --已经打出去的牌个数
    local tileCount = #tilesDiscarded

    local begin = 1
    if self.viewChairID == 1 then
        --自己打出去的牌 需要居中显示
        local s = #discards / 2 --8
        begin = s - math.ceil(tileCount / 2) + 1
        tileCount = begin + tileCount - 1
    end
    local j = 1
    for i = begin, tileCount do
        --local d = discards[(i - 1) % dCount + 1]
        local d = discards[i]
        local tileID = tilesDiscarded[j]
        --dianShu = tileID
        tileMounter:mountTileImage(d, tileID)
        d.visible = true
        j = j + 1
    end
    --这里的 dianShu 只在 单个跟对的时候  有用
    --return dianShu
end

---------------------------------------------
--显示对手玩家的手牌，对手玩家的手牌是暗牌显示
---------------------------------------------
function PlayerView:showHandsForOpponents()
    local player = self.player
    local cardCountOnHand = player.cardCountOnHand

    if self.hands == nil then
        return
    end
    self.hands[1].visible = true
    -- if cardCountOnHand > 3 then
    --     --如果手牌数大于3  则只显示一张牌
    --     self.hands[1]:SetActive(true)
    -- else
    --     --否则 有多少牌就显示多少牌
    --     self:showGaoJing(cardCountOnHand)
    --     for i = 1, cardCountOnHand do
    --         self.hands[i]:SetActive(true)
    --     end
    -- end
    self.handsNumber.text = tostring(cardCountOnHand)
    self.handsNumber.visible = true
end

--隐藏剩牌警告ui
function PlayerView:hideGaoJing()
    -- self.head.gaoJing:SetActive(false)
    -- self.head.gaoJingText.text = "剩牌" .. tostring(cardCountOnHand) .. "张"
end

--显示剩牌警告ui （包括剩牌数量，告警灯）
function PlayerView:showGaoJing()
    -- self.head.gaoJingText.text = "剩牌" .. tostring(cardCountOnHand) .. "张"
    -- if self.head.gaoJing.activeSelf then
    --     return
    -- end
    -- self.head.gaoJing:SetActive(true)
end

---------------------------------------------
--为本人显示手牌，也即是1号playerView(prefab中的1号)
--@param wholeMove 是否整体移动
---------------------------------------------
function PlayerView:showHandsForMe(_, isShow)
    --logger.debug(" showHandsForMe ---------------------", tostring(self.player.cardsOnHand))
    if isShow == nil then
        isShow = true
    end
    local player = self.player
    local cardsOnHand = player.cardsOnHand
    local cardCountOnHand = #cardsOnHand
    local handsClickCtrls = self.handsClickCtrls

    --删除tileID
    --tileID主要是用于点击手牌时，知道该手牌对应那张牌ID
    for i = 1, 16 do
        handsClickCtrls[i].tileID = nil
    end

    --TODO:有必要提取一个clearXXX函数
    --恢复所有牌的位置，由于点击手牌时会把手牌向上移动
    self:restoreHandPositionAndClickCount()

    --手牌要居中显示，所以要计算开始位置跟结束位置
    local cardsHandMax = 16 --满牌数
    local var = math.floor((cardsHandMax - cardCountOnHand) / 2) -- 两边需要空的位置
    local begin = 1 + var
    local endd = cardCountOnHand + var
    local j = 1
    for i = begin, endd do
        local h = self.hands[i]
        tileMounter:mountTileImage(h, cardsOnHand[j])
        h.visible = isShow
        handsClickCtrls[i].tileID = cardsOnHand[j]
        j = j + 1
    end

    -- if cardCountOnHand < 4 then
    -- self:showGaoJing(cardCountOnHand)
    -- end
end

-- 发牌动画
function PlayerView:CenterAlign(ZJHandCards)
    if ZJHandCards == nil then
        return
    end
    local showCardsNum = #ZJHandCards
    --local showCardsNum = 16
    -- for i = 1, originCardsNum do
    --     if not ZJHandCards[i].GetBack() then
    --         showCardsNum = showCardsNum + 1
    --     end
    -- end

    local _cardWidth = 50 -- 牌宽

    local isSingular = showCardsNum % 2 == 1
    local centerCardIdx = showCardsNum % 2 == 1 and math.ceil(showCardsNum / 2) or showCardsNum / 2
    for i = 1, showCardsNum do
        local pos = 568
        if isSingular then
            if i == centerCardIdx then
                pos = 568
            elseif i < centerCardIdx then
                pos = 568 - (centerCardIdx - i) * _cardWidth
            elseif i > centerCardIdx then
                pos = 568 + (i - centerCardIdx) * _cardWidth
            end
        else
            if i <= centerCardIdx then
                pos = 568 - ((centerCardIdx - i) * _cardWidth + _cardWidth / 2)
            elseif i > centerCardIdx then
                pos = 568 + (i - 1 - centerCardIdx) * _cardWidth + _cardWidth / 2
            end
        end
        ZJHandCards[i].x = pos
        ZJHandCards[i].visible = true
        --ZJHandCards[i].setResumePos(pos)
        -- if i < showCardsNum and not _isDiPai then
        -- -- if not ZJHandCards[i].IsWang() then
        -- --     ZJHandCards[i].setShowBigColor(true)
        -- -- end
        -- end
    end
end
--发牌动画，另外两位玩家的 手牌数量 递增。。。没有其他动画效果
function PlayerView:dealOther()
    self.handsNumber.text = 0
    for i = 1, 16 do
        self.myView:DelayRun(
            0.1 * i,
            function()
                self.handsNumber.text = i
            end
        )
    end
end
--发牌动画。。。玩家1 手牌展现
function PlayerView:deal()
    local zjHandArr = self.hands
    local n = #zjHandArr
    for i = 1, n do
        local cardsInfo = {}
        for j = 1, i do
            table.insert(cardsInfo, zjHandArr[j])
        end
        self.myView:DelayRun(
            0.1 * i,
            function()
                --local zjHandCardList = GenerateCardList(CardContainer.tZJHandCards, cardsInfo, CARD_ITEM_TYPE.ZJ_HAND)
                self:CenterAlign(cardsInfo)
            end
        )
    end
end
------------------------------------------
--把手牌摊开，包括对手的暗杠牌，用于一手牌结束时
--显示所有人的暗牌
------------------------------------------
function PlayerView:hand2Exposed()
    --playerView.lights
    if self.lights then
        --不需要手牌显示了，全部摊开
        self:hideLights()

        local player = self.player
        local cardsOnHand = player.cardsOnHand
        local cardCountOnHand = #cardsOnHand

        --手牌要居中显示，所以要计算开始位置跟结束位置
        local cardsHandMax = 16 --满牌数
        local var = math.floor((cardsHandMax - cardCountOnHand) / 2) -- 两边需要空的位置
        local begin = 1 + var
        local endd = cardCountOnHand + var
        local j = 1
        for i = begin, endd do
            local h = self.lights[i]
            tileMounter:mountTileImage(h, cardsOnHand[j])
            h.visible = true
            j = j + 1
        end
    -- local j = 1
    -- for i = begin, endd do
    --     local light = self.lights[j]
    --     tileMounter:mountTileImage(light, cardsOnHand[i])
    --     light:SetActive(true)
    --     j = j + 1
    -- end
    end
end

------------------------------------------
--清除掉由于服务器发下来allowed actions而导致显示出来的view
--例如吃椪杠操作面板等等
------------------------------------------
function PlayerView:clearAllowedActionsView()
    self:hideOperationButtons()
end

--处理玩家拖动牌
function PlayerView:OnItemDrag(_, data)
    if not data.pointerPressRaycast.gameObject or not data.pointerCurrentRaycast.gameObject then
        return
    end
    local startNum = tonumber(data.pointerPressRaycast.gameObject.name)
    local nCurSelNum = tonumber(data.pointerCurrentRaycast.gameObject.name)
    if nCurSelNum == nil then
        return
    end
    if startNum > 0 then
        local nCurStep
        if nCurSelNum <= startNum then
            nCurStep = -1
        else
            nCurStep = 1
        end
        -- logWarn("startNum==>" .. startNum .. "nCurSelNum==>" .. nCurSelNum .. "nCurStep=>" .. nCurStep)
        for i = startNum, nCurSelNum, nCurStep do
            local oSearchObj = self:search(self.dragSelCards, i)
            if not oSearchObj then
                table.insert(self.dragSelCards, i)
            -- self:setGray(self.handsClickCtrls[i].h)
            end
        end
    end
end
function PlayerView:search(t, value)
    for k, v in pairs(t) do
        if v == value then
            return k
        end
    end
end

--处理玩家结束拖动牌
function PlayerView:OnItemDragEnd()
    if self.dragSelCards then
        for _, v in pairs(self.dragSelCards) do
            self:onHandTileBtnClick(v)
        end
    end
end

--处理玩家开始拖动牌
function PlayerView:OnItemBeginDrag()
    self.dragSelCards = {}
end

------------------------------------------
--处理玩家点击手牌按钮
--@param index 从1开始到14，表示手牌序号以及
--  摸牌（对应self.na)
------------------------------------------
function PlayerView:onHandTileBtnClick(index)
    local player = self.player
    if player == nil then
        return
    end

    if not player:isMe() then
        return
    end
    --播放选牌音效
    local handsClickCtrls = self.handsClickCtrls
    -- dfCompatibleAPI:soundPlay("effect/effect_xuanpai")

    local clickCtrl = handsClickCtrls[index]

    clickCtrl.clickCount = clickCtrl.clickCount + 1
    if clickCtrl.clickCount == 1 then
        --self:restoreHandPositionAndClickCount(index)
        self:moveHandUp(index)
    end

    if clickCtrl.clickCount == 2 then
        self:restoreHandUp(index)
    end
end

-------------------------------------------------
--还原所有手牌到它初始化时候的位置，并把clickCount重置为0
-------------------------------------------------
function PlayerView:restoreHandPositionAndClickCount(index)
    for i = 1, 16 do
        if i ~= index then
            self:restoreHandUp(i)
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
    self.handsClickCtrls[index].clickCount = 1
end
-------------------------------------------------
--把手牌还原位置
-------------------------------------------------
function PlayerView:restoreHandUp(index)
    local originPos = self.handsOriginPos[index]
    local h = self.handsClickCtrls[index].h
    h.y = originPos.y
    self.handsClickCtrls[index].clickCount = 0
end
----------------------------------------------------------
--显示玩家头像
----------------------------------------------------------
function PlayerView:showHeadImg()
    if self.head == nil then
        logger.error("showHeadIcon, self.head == nil")
        return
    end
    self.head.headImg.visible = true
    self.head.scoreText.visible = true
    self.head.scoreBg.visible = true
end

----------------------------------------------------------
--如果头像不存在则从微信服务器拉取
----------------------------------------------------------
function PlayerView:getPartnerWeixinIcon(iconUrl, compCallback, failCallback)
    self.playersIcon = self.playersIcon or {}
    self.playersIcon[iconUrl] = self.playersIcon[iconUrl] or {}

    local icon = self.playersIcon[iconUrl]
    if icon.tex ~= nil then
        compCallback(icon.tex)
    else
        if icon.started then
            return
        end
        icon.started = true
        _ENV.CS.NetHelper.HttpGet(
            iconUrl,
            function(www)
                local tex = www.texture
                icon.tex = tex
                compCallback(tex)
                -- TODO: 晚点对接微信拉头像时，处理拉取失败
                failCallback()
            end
        )
    end
end

-- 设置当局分数
function PlayerView:setCurScore()
    local scroe = self.player.totalScores or "0"
    self.head.scoreText.text = tostring(scroe)
end

----------------------------------------------------------
--显示桌主
----------------------------------------------------------
function PlayerView:showOwner()
    local player = self.player

    self.head.roomOwner.visible = player:isMe()
end

--不要动画并等待
function PlayerView:playSkipAnimation()
    self:playerOperationEffectWhitGZ("Effects_zi_buyao", "")
end

----------------------------------------------------------
--特效播放 关张
----------------------------------------------------------
function PlayerView:playerOperationEffectWhitGZ(effectName)
    --新代码
    -- self.aniPos.visible = true
    animation.play("animations/" .. effectName .. ".prefab", self.myView, self.aniPos.x, self.aniPos.y)
end

function PlayerView:updateHeadEffectBox()
    if self.head == nil then
        logger.error("showHeadImg, self.head == nil")
        return
    end

    local player = self.player
    if player == nil then
        logger.error("showHeadImg, player == nil")
        return
    end

    self.head.headImg.visible = true
    -- if self.head.headBox ~= nil and player.avatarID ~= nil and player.avatarID ~= 0 then
    --     local imgPath = string.format("Component/CommonComponent/Bundle/image/box/bk_%d.png",player.avatarID)
    --     self.head.headBox.transform:SetImage(imgPath)
    --     self.head.headBox.transform:GetComponent("Image"):SetNativeSize()
    --     self.head.headBox.transform.localScale = Vector3(0.8,0.8,0.8)
    --     self.head.effectBox.transform.localScale = Vector3(1.25,1.25,1.25)
    -- end
end

return PlayerView
