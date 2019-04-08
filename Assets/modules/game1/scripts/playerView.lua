--[[
    playerview对应玩家的视图，牌桌上有4个playerview
]]
local PlayerView = {}

local mt = {__index = PlayerView}
local fairy = require "lobby/lcore/fairygui"
local logger = require "lobby/lcore/logger"
local proto = require "scripts/proto/proto"
local tileMounter = require("scripts/tileImageMounter")

--这段代码比较屌----------------------------------------
-- function ViewBase:DoPress(clickSound, func, obj, eventData)
--     if clickSound == "selectcard" then
--         Sound.Play(clickSound)
--     end
--     func(obj, eventData)
-- end

-- function ViewBase:AddDrag(node, func, clickSound)
--     clickSound = clickSound
--     if isString(func) then
--         func = self:Func(func)
--     end
--     if isString(node) then
--         node = self:FindChild(node)
--     end
--     if node == self.transform then
--         node.onDrag = function(obj, eventData)
--             if eventData.rawPointerPress == eventData.pointerPress then
--                 ViewBase:DoPress(clickSound, func, obj, eventData)
--             end
--         end
--     elseif node then
--         node.onDrag = function(obj, eventData)
--             ViewBase:DoPress(clickSound, func, obj, eventData)
--         end
--     end
-- end
--add drag 2017.3.2 zy
-- function ViewBase:AddDragEnd(node, func, clickSound)
--     clickSound = clickSound
--     if isString(func) then
--         func = self:Func(func)
--     end
--     if isString(node) then
--         node = self:FindChild(node)
--     end
--     if node == self.transform then
--         node.onEndDrag = function(obj, eventData)
--             if eventData.rawPointerPress == eventData.pointerPress then
--                 ViewBase:DoPress(clickSound, func, obj, eventData)
--             end
--         end
--     elseif node then
--         node.onEndDrag = function(obj, eventData)
--             ViewBase:DoPress(clickSound, func, obj, eventData)
--         end
--     end
-- end

-- function ViewBase:AddBeginDrag(node, func, clickSound)
--     clickSound = clickSound
--     if isString(func) then
--         func = self:Func(func)
--     end
--     if isString(node) then
--         node = self:FindChild(node)
--     end
--     if node == self.transform then
--         node.onBeginDrag = function(obj, eventData)
--             if eventData.rawPointerPress == eventData.pointerPress then
--                 ViewBase:DoPress(clickSound, func, obj, eventData)
--             end
--         end
--     elseif node then
--         node.onBeginDrag = function(obj, eventData)
--             ViewBase:DoPress(clickSound, func, obj, eventData)
--         end
--     end
-- end
--最屌代码完成---------------------------------------------------------------

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

    -- -- self.texiaoPos = myTilesNode.transform:Find("texiaoPos") --特效的位置
    -- local operationPanel = view:GetChild("n31")
    -- 头像相关
    playerView:initHeadView(view)
    -- 手牌
    playerView:initHands(view)
    -- 出牌列表
    playerView:initDiscards(view)
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

function PlayerView:initHands(view)
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
                local card = fairy.UIPackage.CreateObject("runfast", "desk_poker_number_lo")
                card.position = go.position
                myHandTilesNode:AddChild(card)
                -- YY = card.y
                local btn = card:GetChild("n0")
                btn.onClick:Add(
                    function(context)
                        self:onHandTileBtnClick(i)
                    end
                )
                card.name = tostring(i) --把手牌按钮对应的序号记忆，以便点击时可以识别
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
function PlayerView:initDiscards(view)
    -- 打出的牌列表
    local discards = {}
    local myHandTilesNode = view:GetChild("discards")
    for i = 1, 16 do
        local cname = "n" .. i
        local go = myHandTilesNode:GetChild(cname)
        if go ~= nil then
            local card = fairy.UIPackage.CreateObject("runfast", "desk_poker_number_lo")
            card.scale = go.scale
            card.position = go.position
            myHandTilesNode:AddChild(card)
            card.name = tostring(i) --把手牌按钮对应的序号记忆，以便点击时可以识别
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
    local viewUnityNode = self.operationPanel
    local pv = self
    self.skipBtn = viewUnityNode:GetChild("pass")
    self.tipBtn = viewUnityNode:GetChild("tip")
    self.discardBtn = viewUnityNode:GetChild("discard")
    self.skipBtn.onClick:Add(
        function(obj)
            local player = pv.player
            player:onSkipBtnClick(false, obj)
        end
    )
    self.tipBtn.onClick:Add(
        function(obj)
            local player = pv.player
            player:onTipBtnClick(false, obj)
        end
    )
    self.discardBtn.onClick:Add(
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

    head.score = view:GetChild("score")
    head.readyIndicator = view:GetChild("ready")
    head.scoreText = view:GetChild("scoreText")
    head.headImg = headImg

    self.head = head
end

function PlayerView:initPlayerStatus()
    --起始
    local onStart = function()
        logger.debug("llwant ,test onstart ")
        -- head.root:SetActive(true)
        -- head.stateOffline:SetActive(false)
        -- self.infoGroupEmpty:SetActive(false)
        self.head.readyIndicator.visible = false
        if self.checkReadyHandBtn ~= nil then
            self.checkReadyHandBtn:SetActive(false)
        end
    end

    --准备
    local onReady = function(roomstate)
        logger.debug("llwant ,test onReady ")
        -- head.root:SetActive(true)
        -- head.stateOffline:SetActive(false)
        -- self.infoGroupEmpty:SetActive(false)
        self.head.readyIndicator.visible = true
        -- self:showOwner()
        --onReset(roomstate)
    end

    --离线
    local onLeave = function(roomstate)
        logger.debug("llwant ,test onLeave ")
        self.head.readyIndicator.visible = false
        -- self.infoGroupEmpty:SetActive(false)
        -- head.stateOffline:SetActive(true)
        --onReset(roomstate)
    end

    --正在玩
    local onPlaying = function(roomstate)
        logger.debug("llwant ,test onPlaying ")
        self.head.readyIndicator.visible = false
        -- self.infoGroupEmpty:SetActive(false)
        -- head.root:SetActive(true)
        -- head.stateOffline:SetActive(false)
        -- self:showOwner()
        --onReset(roomstate)
    end

    ----玩家状态
    -- PSNone = 0
    -- PSReady = 1
    -- PSOffline = 2
    -- PSPlaying = 3
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
    if self.head.effectBox ~= nil then
        self.head.effectBox:SetActive(isShow)
    end
end

------------------------------------
--从根节点上隐藏所有
------------------------------------
function PlayerView:hideAll()
    -- self.head.readyIndicator.visible = false
    for _, v in ipairs(self.head) do
        v.visible = false
    end
    if self.viewChairID ~= 1 then
        self.handsNumber.text = ""
    end
    self:hideHands()
    self:hideDiscarded()
end

------------------------------------
--新的一手牌开始，做一些清理后再开始
------------------------------------
function PlayerView:resetForNewHand()
    self:hideHands()
    -- self:hideFlowers()
    -- self:hideLights()
    -- self:clearDiscardable()
    self:hideDiscarded()
    --特效列表
    --self:cleanEffectObjLists()
    --self.head.ting:SetActive(false)
    -- self:setHeadEffectBox(false)
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
    local discards = self.discards
    for _, d in ipairs(discards) do
        d.visible = false
    end
end

-------------------------------------
--隐藏摊开牌列表
-------------------------------------
function PlayerView:hideLights()
    for _, h in ipairs(self.lights) do
        h:SetActive(false)
    end
end

-------------------------------------
--隐藏手牌列表
--其实是把整行都隐藏了
-------------------------------------
function PlayerView:hideHands()
    for _, h in ipairs(self.hands) do
        h.visible = false
    end
end

------------------------------------------
--显示打出去的牌，明牌显示
------------------------------------------
function PlayerView:showDiscarded(tilesDiscarded)
    local player = self.player

    --先隐藏所有的打出牌节点
    self:hideDiscarded()
    local discards = self.discards

    --已经打出去的牌个数
    local tileCount = #tilesDiscarded

    local begin = 1
    if tileCount < 4 then
        --居中显示
        begin = 2
        tileCount = tileCount + 1
    end

    --打出牌的挂载点个数
    --local dCount = #discards
    --从那张牌开始挂载，由于tileCount可能大于dCount
    --因此，需要选择tilesDiscarded末尾的dCount个牌显示即可
    -- local begin = tileCount - dCount + 1
    -- if begin < 1 then
    --     begin = 1
    -- end
    --local dianShu = 0
    --i计数器对应tilesDiscarded列表
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
function PlayerView:showGaoJing(cardCountOnHand)
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
function PlayerView:showHandsForMe(wholeMove, isShow)
    --logger.debug(" showHandsForMe ---------------------" .. tostring(self.player.cardsOnHand))
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

    --蛋疼需求，手牌要居中显示，所以要计算开始位置跟结束位置
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

    if cardCountOnHand < 4 then
    -- self:showGaoJing(cardCountOnHand)
    end
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
        if isSingular then
            if i == centerCardIdx then
                pos = Vector3(0, 0, 0)
            elseif i < centerCardIdx then
                pos = Vector3(0 - (centerCardIdx - i) * _cardWidth, 0, 0)
            elseif i > centerCardIdx then
                pos = Vector3((i - centerCardIdx) * _cardWidth, 0, 0)
            end
        else
            if i <= centerCardIdx then
                pos = Vector3(0 - ((centerCardIdx - i) * _cardWidth + _cardWidth / 2), 0, 0)
            elseif i > centerCardIdx then
                pos = Vector3((i - 1 - centerCardIdx) * _cardWidth + _cardWidth / 2, 0, 0)
            end
        end
        ZJHandCards[i].transform.localPosition = pos
        ZJHandCards[i]:SetActive(true)
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
    for i = 1, 16 do
        self.viewUnityNode:DelayRun(
            0.06 * i,
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
        self.viewUnityNode:DelayRun(
            0.06 * i,
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
function PlayerView:hand2Exposed(wholeMove)
    --playerView.lights
    --不需要手牌显示了，全部摊开
    self:hideLights()

    local player = self.player
    local cardsOnHand = player.cardsOnHand
    local cardCountOnHand = #cardsOnHand

    --蛋疼需求，手牌要居中显示，所以要计算开始位置跟结束位置
    local cardsHandMax = 16 --满牌数
    local var = math.floor((cardsHandMax - cardCountOnHand) / 2) -- 两边需要空的位置
    local begin = 1 + var
    local endd = cardCountOnHand + var
    local j = 1
    for i = begin, endd do
        local h = self.lights[i]
        tileMounter:mountTileImage(h, cardsOnHand[j])
        h:SetActive(true)
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

------------------------------------------
--清除掉由于服务器发下来allowed actions而导致显示出来的view
--例如吃椪杠操作面板等等
------------------------------------------
function PlayerView:clearAllowedActionsView(discardAble)
    self:hideOperationButtons()

    --self.checkReadyHandBtn:SetActive(false)
end

--处理玩家拖动牌
function PlayerView:OnItemDrag(cardObj, data)
    if not data.pointerPressRaycast.gameObject or not data.pointerCurrentRaycast.gameObject then
        return
    end
    local startNum = tonumber(data.pointerPressRaycast.gameObject.name)
    local nCurSelNum = tonumber(data.pointerCurrentRaycast.gameObject.name)
    if nCurSelNum == nil then
        return
    end
    if startNum > 0 then
        local nCurStep = 0
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
function PlayerView:OnItemDragEnd(cardObj, data)
    if self.dragSelCards then
        for k, v in pairs(self.dragSelCards) do
            self:onHandTileBtnClick(v)
        end
    end
end
--处理玩家开始拖动牌
function PlayerView:OnItemBeginDrag(cardObj, data)
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
        --logger.debug(" drag able")
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
        self.dragEffect.localPosition = Vector3(0, 0, 0)
        self.dragEffect:SetActive(true)
    end

    --去掉拖动效果
    local function detachEffect()
        self.dragEffect:SetActive(false)
    end

    dragGo.onBeginDrag = function(obj, eventData)
        --logger.debug(" darg onbegindrag")
        if not enable then
            return
        end

        self:restoreHandPositionAndClickCount(index)
        attachEffect(obj)
    end

    dragGo.onDown = function(obj, eventData)
        enable = dragable()
        --关闭拖动特效
        detachEffect()

        if not enable then
            startPos = dragGo.localPosition
            return
        end
        siblingIndex = dragGo:GetSiblingIndex()

        --logger.debug(" drag ondown")
        local x1 = dragGo.localPosition.x - dragGo.sizeDelta.x * 0.5
        local x2 = dragGo.localPosition.x + dragGo.sizeDelta.x * 0.5
        local y1 = dragGo.localPosition.y - dragGo.sizeDelta.y * 0.5
        local y2 = dragGo.localPosition.y + dragGo.sizeDelta.y * 0.5
        rect = {x1, x2, y1, y2}

        startPos = dragGo.localPosition
        dragGo:SetAsLastSibling()
    end

    dragGo.onMove = function(obj, eventData, pos)
        if not enable then
            dragGo.localPosition = startPos
            return
        end
        -- obj.position = pos
    end

    dragGo.onEndDrag = function(obj, eventData)
        if not enable then
            return
        end

        --拖牌结束立即不显示
        dragGo:SetActive(false)

        dragGo:SetSiblingIndex(siblingIndex)
        --logger.debug(" darg onenddrag")
        detachEffect()
        if pointIsInRect(dragGo.localPosition) then
            dragGo:SetActive(true)
            dragGo.localPosition = startPos
        else
            --重置打出的牌位置（TODO：需要测试当网络不好的情况下onPlayerDiscardTile发送数据失败，界面刷新情况）
            dragGo:SetActive(false)
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
        logError("showHeadIcon, self.head == nil")
        return
    end
    self.head.headImg.visible = true

    -- if self.head.headImg == nil then
    --     logError("showHeadIcon, self.head.headImg == nil")
    --     return
    -- end

    -- local player = self.player
    -- if player == nil then
    --     logError("showHeadIcon, player == nil")
    --     return
    -- end

    -- if player.sex == 1 then
    --     self.head.headImg.sprite = dfCompatibleAPI:loadDynPic("playerIcon/boy_img")
    -- else
    --     self.head.headImg.sprite = dfCompatibleAPI:loadDynPic("playerIcon/girl_img")
    -- end

    -- if player.headIconURI then
    --     logger.debug("showHeadImg player.headIconURI = "..player.headIconURI)
    --     tool:SetUrlImage(self.head.headImg.transform, player.headIconURI)
    -- else
    --     logError("showHeadIcon,  player.headIconURI == nil")
    -- end

    -- local boxImg = self.head.headBox.transform:GetComponent("Image")
    -- boxImg.sprite = self.head.defaultHeadBox.sprite
    -- boxImg:SetNativeSize()

    -- self.head.headBox.transform.localScale = Vector3(1,1,1)
    -- self.head.effectBox.transform.localScale = Vector3(1,1,1)

    -- if self.head.headBox ~= nil and player.avatarID ~= nil and player.avatarID ~= 0 then
    --     local imgPath = string.format("Component/CommonComponent/Bundle/image/box/bk_%d.png",player.avatarID)
    --     self.head.headBox.transform:SetImage(imgPath)
    --     self.head.headBox.transform:GetComponent("Image"):SetNativeSize()
    --     self.head.headBox.transform.localScale = Vector3(0.8,0.8,0.8)
    --     self.head.effectBox.transform.localScale = Vector3(1.25,1.25,1.25)
    -- end
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
        local www =
            HttpGet(
            iconUrl,
            function(www)
                local tex = www.texture
                icon.tex = tex
                compCallback(tex)
            end,
            function(error)
                if failCallback then
                    failCallback(error)
                end
            end
        )
        if www and not www.error then
            icon.started = false
        end
    end
end

----------------------------------------------------------
--显示桌主
----------------------------------------------------------
function PlayerView:showOwner()
    if self.head == nil then
        logError("showOwner, self.head == nil")
        return
    end

    if self.head.roomOwnerFlag == nil then
        logError("showOwner, self.head.owner == nil")
        return
    end

    local player = self.player
    local room = player.room

    if player.userID == room.ownerID then
        self.head.roomOwnerFlag:SetActive(true)
    else
        self.head.roomOwnerFlag:SetActive(false)
    end
end

--不要动画并等待
function PlayerView:playSkipAnimation()
    --local waitCo = coroutine.running()
    -- self:playerOperationEffectWhitGZ(dfConfig.EFF_DEFINE.SUB_GUANZHANG_BUYAO, "buyao")
    --self.player:playSound("hua")
    -- self.viewUnityNode:DelayRun(
    --     1.5,
    --     function()
    --         local flag, msg = coroutine.resume(waitCo)
    --         if not flag then
    --             logError(msg)
    --             return
    --         end
    --     end
    -- )
    --coroutine.yield()
end

----------------------------------------------------------
--特效播放
----------------------------------------------------------
function PlayerView:playerOperationEffect(effectName, sound)
    local effectObj = Animator.Play(dfConfig.PATH.EFFECTS .. effectName .. ".prefab", self.viewUnityNode.order)

    effectObj:SetParent(self.operationTip)
    effectObj.localPosition = Vector3(0, 0, 0)

    if sound ~= nil then
        self.player:playSound(sound)
    end
end

----------------------------------------------------------
--特效播放 关张
----------------------------------------------------------
function PlayerView:playerOperationEffectWhitGZ(effectName, sound)
    local effectObj = Animator.Play(dfConfig.PATH.EFFECTS_GZ .. effectName .. ".prefab", self.viewUnityNode.order + 1)

    -- local effectObj =
    --     Animator.PlayLoop(
    --         dfConfig.PATH.EFFECTS_GZ .. effectName .. ".prefab",
    --     self.viewUnityNode.order
    -- )
    effectObj:SetParent(self.operationTip)
    effectObj.localPosition = Vector3(0, 0, 0)
    --table.insert(self.effectObjLists, effectObj)
    if sound ~= nil and sound ~= "" then
        self.player:playSound(sound)
    end
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

function PlayerView:updateHeadEffectBox()
    if self.head == nil then
        logRed("showHeadImg, self.head == nil")
        return
    end

    local player = self.player
    if player == nil then
        logRed("showHeadImg, player == nil")
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
