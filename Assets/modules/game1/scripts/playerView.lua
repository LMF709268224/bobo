--[[
    playerview对应玩家的视图，牌桌上有4个playerview
]]
local PlayerView = {}

local mt = {__index = PlayerView}
local fairy = require "lobby/lcore/fairygui"
local logger = require "lobby/lcore/logger"
local proto = require "scripts/proto/proto"
--local AgariIndex = require "dfMahjong/AgariIndex"
-- local tileMounter = require(dfPath .. "dfMahjong/tileImageMounter")
-- local Loader = require(dfPath .. "dfMahjong/spriteLoader")
-- local userDataModule = g_ModuleMgr:GetModule(ModuleName.DATASTORAGE_MODULE)
-- local dfConfig = require(dfPath .. "dfMahjong/dfConfig")
-- local tool = g_ModuleMgr:GetModule(ModuleName.TOOLLIB_MODULE)

-- local dfCompatibleAPI = require(dfPath .. "dfMahjong/dfCompatibleAPI")

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
    elseif (viewChairID == 2) then
        view = viewUnityNode:GetChild("playerRight")
    elseif (viewChairID == 3) then
        view = viewUnityNode:GetChild("playerLeft")
    end
    playerView.viewChairID = viewChairID
    playerView.viewUnityNode = viewUnityNode
    local head = {}
    local headImg = view:GetChild("head")
    headImg.visible = false
    local score = view:GetChild("score")
    score.visible = true
    local scoreText = view:GetChild("scoreText")
    scoreText.visible = true

    head.scoreText = scoreText
    head.headImg = headImg
    -- myTilesNode.visible = true
    -- playerView.tilesRoot = myTilesNode

    -- -- self.texiaoPos = myTilesNode.transform:Find("texiaoPos") --特效的位置
    -- local operationPanel = view:GetChild("n31")
    -- 手牌列表
    local hands = {}
    local handsOriginPos = {}
    local handsClickCtrls = {}
    if (viewChairID == 1) then
        local myHandTilesNode = view:GetChild("hands")
        for i = 1, 16 do
            local cname = "n" .. i
            local go = myHandTilesNode:GetChild(cname)
            if go ~= nil then
                local card = fairy.UIPackage.CreateObject("runfast", "desk_poker_number_lo")
                card.position = go.position

                -- if i == 1 then
                --     local flag = card:GetChild("n2")
                --     flag.url = "ui://p966ud2tef8pw"
                -- end

                myHandTilesNode:AddChild(card)
                YY = card.y
                local btn = card:GetChild("n0")
                btn.onClick:Add(
                    function(context)
                        if card.y >= YY then
                            card.y = card.y - 30
                        else
                            card.y = card.y + 30
                        end
                    end
                )

        -- local h = myHandTilesNode.transform:Find(tostring(i))
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
        --订阅点击事件
        --TODO: 增加drag/drop
        -- viewUnityNode:AddClick(
        --     h,
        --     function(obj)
        --         playerView:onHandTileBtnClick(i)
        --     end,
        --     {isMute = true}
        -- )
        --playerView:onDrag(h, i)
        end
    else
        --用于显示手牌数量
        playerView.handsNumber =view:GetChild("handsNum")
    end
    playerView.hands = hands
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

    playerView.handsOriginPos = handsOriginPos --记忆原始的手牌位置，以便点击手牌时可以往上弹起以及恢复
    playerView.handsClickCtrls = handsClickCtrls -- 手牌点击时控制数据结构

    -- -- 打出的牌列表
    -- local discards = {}
    -- local myDicardTilesNode = myTilesNode.transform:Find("Outs")
    -- for i = 1, 16 do
    --     local h = myDicardTilesNode.transform:Find(tostring(i))
    --     discards[i] = h
    -- end
    -- playerView.discards = discards
    -- --用于保存所有关张的loop特效（不要，三带二，炸弹，顺子等等特效，后面便于清理）
    -- --playerView.effectObjLists = {}
    -- -- 下面这个Light得到的牌表，是用于结局时摊开牌给其他人看 (也可用于明牌)
    -- local lights = {}
    -- local myLightTilesNode = myTilesNode.transform:Find("Light")
    -- for i = 1, 16 do
    --     local h = myLightTilesNode.transform:Find(tostring(i))
    --     lights[i] = h
    -- end
    -- playerView.lights = lights

    -- ready状态指示
    playerView.readyIndicator = view:GetChild("ready")
    -- -- 打出的牌放大显示
    -- playerView.discardTips = viewUnityNode.transform:Find("OneOuts/" .. viewChairID)
    -- playerView.discardTipsTile = playerView.discardTips:Find("Card")
    -- playerView.discardTipsYellow = playerView.discardTips:Find("Card/Image")

    -- -- 倒计时 位置
    -- playerView.countdownPos = viewUnityNode.transform:Find("Countdown/" .. viewChairID)

    -- --特效提示位置
    -- playerView.operationTip = viewUnityNode.transform:Find("OpTips/" .. viewChairID)

    -- --拖动效果
    -- playerView.dragEffect = viewUnityNode.transform:Find("Effects_tuodong")

    -- --头像信息
    -- playerView.infoGroup = viewUnityNode.transform:Find("PlayInfoGroup/" .. viewChairID)
    -- playerView.infoGroupEmpty = viewUnityNode.transform:Find("PlayInfoGroup/" .. viewChairID .. "empty")
    -- --playerView.infoGroupPos = viewUnityNode.transform:Find("PlayInfoGroup/" .. viewChairID .. "pos")

    -- 头像相关
    playerView:initHeadView()

    -- -- 头像弹框
    -- playerView:initHeadPopup()

    if viewChairID == 1 then
        playerView:initOperationButtons()
    end
    playerView.head = head

    return playerView
end
--把胡按钮里面的特效 层级调高。。。
-- function PlayerView:huBtnOrderAdd(view)
--     local renderers = view.transform:GetComponentsInChildren(typeof(UnityEngine.Renderer))
--     local Len = renderers.Length
--     if Len > 0 then
--         for idx = 0, Len - 1  do
--             renderers[idx].sortingOrder = self.viewUnityNode.order + 1
--         end
--     end
-- end
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
        self.discardBtn,
        self.discardHuiBtn,
        self.skipHuiBtn,
        self.tipHuiBtn
    }
    self:hideOperationButtons()
end
------------------------------------
-- 设置金币数显示（目前是累计分数）
-----------------------------------
function PlayerView:setGold(gold)
    if checkint(gold) < 0 then
        self.head.goldText1:Show()
        self.head.goldText:Hide()
        self.head.goldText1.text = tostring(gold)
    else
        self.head.goldText1:Hide()
        self.head.goldText:Show()
        self.head.goldText.text = tostring(gold)
    end
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
function PlayerView:initHeadView()
    local head = {}
    --local viewChairID = self.viewChairID
    local viewUnityNode = self.viewUnityNode

    -- local infoGroup = self.infoGroup
    -- head.root = infoGroup
    -- 文字聊天框
    -- head.textChat = infoGroup.transform:Find("TextChat")
    -- 表情聊天
    -- head.faceChat = infoGroup.transform:Find("FaceChat")
    -- 语音聊天
    -- head.playerVoiceNode = infoGroup.transform:Find("VoiceImage")
    -- head.playerVoiceTextNode = infoGroup.transform:Find("VoiceImage/LenText")
    -- 动画控制
    -- head.playerVoiceAction = {}

    -- 房间拥有者标志
    -- head.roomOwnerFlag = infoGroup.transform:Find("owner")
    -- 离开状态标志
    -- head.stateLeave = infoGroup.transform:Find("Exit")
    -- 离线状态标志
    -- head.stateOffline = infoGroup.transform:Find("OffLine")

    --庄家标志
    -- head.bankerFlag = infoGroup.transform:Find("BankerTag")
    -- head.continuousBankerFlag = infoGroup.transform:Find("BankerContinuousTag")
    --告警

    --把告警里面的特效 层级调高。。。
    -- head.gaoJing = infoGroup.transform:Find("GaoJing")
    -- head.gaoJingText = infoGroup.transform:SubGet("GaoJing/Number/Text", "Text")
    -- local gaoJingTeXiao = infoGroup.transform:Find("GaoJing/Effects_zi_jingling")
    -- local uiDepth = gaoJingTeXiao:GetComponent("UIDepth")
    -- if not uiDepth then
    --     uiDepth = gaoJingTeXiao:AddComponent(typeof(UIDepth))
    -- end
    -- uiDepth.canvasOrder = self.viewUnityNode.order + 1

    --头像特效框
    --head.effectBox = infoGroup.transform:Find("HeadBox/Effects_tuxiangkuang")
    -- head.headBox = infoGroup.transform:Find("HeadBox")

        --生成默认的头像和框，用于刷新玩家头像
    --log("--log init default sprite")
    -- local defaultNode = infoGroup.transform:Find("HeadImg")
    -- local headImgNode = tool:UguiAddChild(infoGroup.transform, defaultNode, "defaultHeadImg")
    -- headImgNode:SetActive(false)
    -- head.defaultHeadImg = headImgNode:GetComponent("Image")

    -- local headBoxNode = tool:UguiAddChild(infoGroup.transform, defaultNode, "defaultHeadBox")
    -- headBoxNode:SetActive(false)
    -- head.defaultHeadBox = headBoxNode:GetComponent("Image")
    -- head.defaultHeadBox.sprite = head.headBox:GetComponent("Image").sprite

    -- head.effectBox = infoGroup.transform:Find("HeadBox/TeXiao")
    -- local touxiangkuang = infoGroup.transform:Find("HeadBox/TeXiao/Effects_UI_touxiang")
    -- local uiDepth2 = touxiangkuang:GetComponent("UIDepth")
    -- if not uiDepth2 then
    --     uiDepth2 = touxiangkuang:AddComponent(typeof(UIDepth))
    -- end
    -- uiDepth2.canvasOrder = self.viewUnityNode.order + 1
    --头像
    --TODO: 微信用户需要拉取头像，参考原LZOnlineView2.lua
    -- head.headImg = viewUnityNode:SubGet("PlayInfoGroup/" .. self.viewChairID .. "/HeadImg", "Image")
    --名字
    --TODO: 名字太长需要截断，参考原LZOnlineView2.lua
    -- head.nameText = viewUnityNode:SubGet("PlayInfoGroup/" .. self.viewChairID .. "/NameText", "Text")
    --分数
    -- head.goldText = viewUnityNode:SubGet("PlayInfoGroup/" .. self.viewChairID .. "/GoldText", "Text")
    -- head.goldText1 = viewUnityNode:SubGet("PlayInfoGroup/" .. self.viewChairID .. "/GoldText1", "Text")

    --重置位置
    -- local onReset = function (roomstate)
    --     --  房间状态
    --     if roomstate == pkproto2.SRoomPlaying then
    --         self.infoGroup.localPosition = self.infoGroupPos.localPosition
    --     end
    -- end

    --起始
    local onStart = function()
        logger.debug("llwant ,test onstart ")
        -- head.root:SetActive(true)
        -- head.stateOffline:SetActive(false)
        -- self.infoGroupEmpty:SetActive(false)
        self.readyIndicator.visible = false
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
        self.readyIndicator.visible = true
        -- self:showOwner()
        --onReset(roomstate)
    end

    --离线
    local onLeave = function(roomstate)
        logger.debug("llwant ,test onLeave ")
        self.readyIndicator.visible = false
        -- self.infoGroupEmpty:SetActive(false)
        -- head.stateOffline:SetActive(true)
        --onReset(roomstate)
    end

    --正在玩
    local onPlaying = function(roomstate)
        logger.debug("llwant ,test onPlaying ")
        self.readyIndicator.visible = false
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

    --更新庄家UI
    local updateBanker = function(isBanker, isContinue)
        if isBanker then
            if isContinue then
                head.bankerFlag:SetActive(false)
                head.continuousBankerFlag:SetActive(true)
            else
                head.bankerFlag:SetActive(true)
                head.continuousBankerFlag:SetActive(false)
            end
        else
            head.bankerFlag:SetActive(false)
            head.continuousBankerFlag:SetActive(false)
        end
    end
    head.onUpdateBankerFlag = updateBanker

    self.head = head
end

------------------------------------
-- 设置头像特殊效果是否显示（当前出牌者则显示）
-----------------------------------
function PlayerView:setHeadEffectBox(isShow)
    if self.head.effectBox ~= nil then
        self.head.effectBox:SetActive(isShow)
    end
end

function PlayerView:updateHeadPopup()
    --更新钻石 红心 数据
    local viewChairID = self.viewChairID
    local pPath = "OtherInfoBg"
    if viewChairID == 1 then
        pPath = "MyInfoBg"
    end
    local path = "UserInfo/" .. pPath .. "/Info"
    self.viewUnityNode:SetText(path .. "/ImageCoin/TextAmount", self.player.charm)
    self.viewUnityNode:SetText(path .. "/ImageZuan/TextAmount", self.player.diamond)
end
------------------------------------
-- 保存点击头像弹出框的内容节点
-----------------------------------
function PlayerView:initHeadPopup()
    local headPopup = {}
    local viewChairID = self.viewChairID
    local viewUnityNode = self.viewUnityNode
    local pPath = "OtherInfoBg"
    if viewChairID == 1 then
        pPath = "MyInfoBg"
    end
    headPopup.headInfobg = viewUnityNode.transform:Find("UserInfo/" .. pPath)
    local uiDepth = headPopup.headInfobg:GetComponent("UIDepth")
    if not uiDepth then
        uiDepth = headPopup.headInfobg:AddComponent(typeof(UIDepth))
    end
    uiDepth.canvasOrder = self.viewUnityNode.order + 2
    -- local userInfoBgPos = {}
    -- for i = 2, 3 do
    --     userInfoBgPos[i] = viewUnityNode.transform:Find("UserInfo/Pos" .. i)
    -- end
    local iconPath = string.format("PlayInfoGroup/%d/HeadImg", viewChairID)
    local headBoxIconPath = string.format("PlayInfoGroup/%d/HeadBox", viewChairID)


    if not g_ModuleMgr:GetModule("ConfigModule"):IsIosAudit() then
        self.viewUnityNode:AddClick(iconPath, function()

            -- 点击头像,关闭已经打开的页面
            local player = self.player
            self.player.room.curActiveChairID = player.chairID
            local playerViews = self.player.room.roomView.playerViews
            local neededReturn = false
            for i=1,3 do
                if  playerViews[i].headPopup ~= nil and  playerViews[i].headPopup.headInfobg ~= nil and  playerViews[i].headPopup.headInfobg.activeSelf == true then
                    neededReturn = true

                        playerViews[i].headPopup.headInfobg:SetActive(false)
                        if playerViews[i].headPopup.mask ~= nil then
                            playerViews[i].headPopup.mask:SetActive(false)
                        end

                    end
                end
                if neededReturn then
                    return
                end
                local sprite = self.viewUnityNode:SubGet(iconPath, "Image").sprite
                local path = "UserInfo/" .. pPath .. "/Info"

                local IconObj = self.viewUnityNode:SubGet(path .. "/ImageIcon", "Image")
                IconObj.sprite = sprite


                local headBoxSprite = self.viewUnityNode:SubGet(headBoxIconPath, "Image").sprite
                local headBoxIcon = self.viewUnityNode:SubGet(path.."/ImageIcon/Image", "Image")
                logger.debug("headBoxIconPath = "..headBoxIconPath)
                headBoxIcon.sprite = headBoxSprite
                headBoxIcon:SetNativeSize()
                headBoxIcon.transform.localScale = Vector3(1.25,1.25,1)

                if player.avatarID ~= nil and player.avatarID ~= 0 then
                    logger.debug("player.avatarID ~= nil and player.avatarID ~= 0 player.avatarID = "..player.avatarID)
                    headBoxIcon.transform.localScale = Vector3(1,1,1)
                end

                local nameSte = tool:FormotGameNickName(self.player.nick, 8)

                self.viewUnityNode:SetText(path .. "/TextName", nameSte)
                self.viewUnityNode:SetText(path .. "/TextID", "ID:" .. self.player.userID)
                --local score = self.tscore[viewChairID]
                -- local charm = self.player.charm
                -- local format = NumberFormat(math.abs(charm))
                -- if charm < 0 then
                --     format = "-"..format
                -- end
                self.viewUnityNode:SetText(path .. "/ImageCoin/TextAmount", self.player.charm)
                self.viewUnityNode:SetText(path .. "/ImageZuan/TextAmount", self.player.diamond)
                -- local iptext = "无法定位"
                self.viewUnityNode:SetText(path .. "/TextIP", "IP:" .. self.player.ip)

                local total = tool:FormatChinaNum(self.player.dfHands, 2)
                self.viewUnityNode:SetText(path .. "/TextTotal", "总局数:" .. total)

                -- 段位标志 by kevin 2018 05 18
                local segmentLogo = self.viewUnityNode.transform:Find(path.."/SegmentLogo")
                local segmentLogoText = self.viewUnityNode.transform:Find(path.."/SegmentLogoText")
                segmentLogo:SetImage(g_dataModule:GetDanIcon(self.player.dan))
                segmentLogoText:SetImage(g_dataModule:GetDanNameImg(self.player.dan))
                self.player.room.roomView:FunctionSwitch()
                local iconGender = self.viewUnityNode:SubGet(path .. "/ImageSex", "Image")

                local genderSprite = dfCompatibleAPI:loadDynPic("playerIcon/nv_in_head")
                if self.player.sex == 1 then
                    genderSprite = dfCompatibleAPI:loadDynPic("playerIcon/nan_in_head")
                end

                iconGender.sprite = genderSprite
                local location = nil
                if #self.player.location > 0 then
                    logger.debug(" loc:" .. self.player.location)
                    location = Json.decode(self.player.location)
                end
                -- 与玩家的距离设置
                local distanceObj = self.viewUnityNode.transform:Find(path.."/Distance")
                local distanceText = {}
                for i = 1, 3 do
                    distanceText[i] = self.viewUnityNode.transform:Find(path.."/Distance/Distance" .. i)
                    distanceText[i]:SetActive(false)
                end
                local function setDistanceText()
                    logger.debug(" comming to setDistanceText !!")
                    local gpsModule = g_ModuleMgr:GetModule(ModuleName.GPS_MODULE)
                    local players = {}
                    players = self.player.room.players
                    local j = 1
                    for i, v in pairs(players) do
                        local dLocation = nil -- 用于解析位置进行判断
                        local nick = ""
                        if #v.location > 0 then
                            logger.debug(" loc:"..v.location)
                            dLocation = Json.decode(v.location)
                        end
                        if self.player.userID ~= i then
                            -- 获取昵称截断
                            nick = tool:FormotGameNickName(v.nick,8)
                            -- 获取距离
                            local dText = ""
                            if dLocation ~= nil and dLocation.address ~= nil and type(dLocation.address) == "table" then
                                dis = gpsModule:CalculateLineDistance(self.player.location,v.location)
                                if dis > 1000 then
                                    dText = "与玩家 " .. nick .. " 距离 " .. tool:SubFloatNum(dis/1000,2) .. "公里"
                                else
                                    local d = tool:SubFloatNum(dis,2)
                                    if d < 20 then
                                        dText ="<color=#ea3d3d>与玩家 " .. nick .. " 距离 " .. d .. "米</color>"
                                    else
                                        dText = "与玩家 " .. nick .. " 距离 " .. d .. "米"
                                    end
                                end
                            else
                                dText = nick .. "  未开启定位"
                            end
                            distanceText[j].text = dText
                            distanceText[j]:SetActive(true)
                            j = j + 1
                        end
                    end
                end

                local owner = self.player.room:me()
                if self.player.userID == owner.userID then
                    local oLocation = nil
                    if #owner.location > 0 then
                        oLocation = Json.decode(owner.location)
                    end
                    if oLocation and type(oLocation.address) == "table" then
                        setDistanceText()
                        distanceObj.text = ""
                    else
                        distanceObj.text = "您未开启定位"
                    end
                else
                    if location ~= nil and location.address ~= nil and type(location.address) == "table" then
                        setDistanceText()
                        distanceObj.text = ""
                    else
                        distanceObj.text = "对方未开启定位"
                    end
                end
                distanceObj:SetActive(true)

                if viewChairID ~= 1 then
                    -- 踢出用戶
                    local kickoutBtn = self.viewUnityNode.transform:Find(path .. "/Tick")
                    self.viewUnityNode:AddClick(
                        kickoutBtn,
                        function()
                            self:kickoutPlayer()
                        end
                    )
                    --道具提示Toggle
                    local donateToggle = self.viewUnityNode:SubGet(path .. "/Toggle", "Toggle")
                    local accountCfg = userDataModule.accountCfg
                    if accountCfg.donateToggle == nil then
                        -- 购买道具不再提示默认勾选
                        userDataModule:Save("accountCfg", "donateToggle", true)
                        accountCfg.donateToggle = true
                    end
                    donateToggle.isOn = accountCfg.donateToggle
                    UIEvent.AddToggleValueChange(
                        donateToggle.transform,
                        function()
                            local v = donateToggle.isOn
                            userDataModule:Save("accountCfg", "donateToggle", v)
                        end
                    )
                    --道具
                    local donateContent = self.viewUnityNode.transform:Find(path.."/Content/Viewport/Content")
                    local donateModel = self.viewUnityNode.transform:Find(path.."/Content/Viewport/Content/Item")
                    self.viewUnityNode.donateBtns = self.viewUnityNode.donateBtns or {}
                    if #self.viewUnityNode.donateBtns == 0 then
                        for i = 1, 100 do
                            local prop = self:getRoomProp(i)
                            if prop then
                                local donateBtn = self.viewUnityNode:AddPrefab(donateModel,donateContent,"Prop"..i)
                                donateBtn:Show()
                                table.insert(self.viewUnityNode.donateBtns,donateBtn)
                                local propIcon = donateBtn:Find("ImageConf")
                                local charmText = donateBtn:Find("TextXin")
                                local diamondText = donateBtn:Find("TextZuan")
                                local propNum = donateBtn:Find("ItemNum")
                                charmText.text = prop["charm"]
                                diamondText.text = prop["diamond"]

                                local propID = prop["propID"]
                                local num = g_dataModule:GetPackagePropNum(propID)
                                logger.debug("num"..tostring(num)..", propID:"..tostring(propID))
                                if num and num ~=0 then
                                    propNum:SetActive(true)
                                    local propNumText = propNum:Find("Text")
                                    propNumText.text = "免费"..tostring(num).."次"
                                end
                                propIcon:SetImage("Component/CommonComponent/Bundle/image/prop/"..propID..".png")
                            else
                                break
                            end
                        end
                        if donateContent.childCount > 9 then
                            donateContent.localPosition = Vector3(0,50,0)
                        end
                    end
                    for i,donateBtn in ipairs(self.viewUnityNode.donateBtns) do
                        self.viewUnityNode:AddClick(donateBtn,
                        function()
                            self:onClickDonateBtn(i,donateToggle.isOn)
                        end)
                    end
                end

                local addresstext = "对方未开启定位"
                if location ~= nil and location.address ~= nil and type(location.address) == "table" then
                    if self.player:isMe() then
                        --自己的都显示formatAddress
                        addresstext = location.address.formatted_address
                    else
                        -- if self.player.room.safeLocations ~= nil and not self.player.room.safeLocations[self.player.chairID] then
                        --     --非安全情况下显示 formatAddress
                        --     addresstext = location.address.formatted_address
                        -- else
                        --     --安全情况下显示 province + city + district
                        --     local address = location.address
                        --     addresstext = address.province .. address.city .. address.district
                        -- end
                        local address = location.address
                        addresstext = address.province .. address.city .. address.district
                    end
                else
                    if self.player:isMe() then
                        addresstext = "您未开启定位"
                    end
                end
                self.viewUnityNode:SetText(path .. "/TextAddress", "地址:" .. addresstext)

                headPopup.headInfobg:SetActive(true)
                -- 点击背景,关闭头像详情
                headPopup.mask = self.viewUnityNode.transform:Find("UserInfo/Mask")
                self.viewUnityNode:AddClick(
                    headPopup.mask,
                    function()
                        headPopup.headInfobg:SetActive(false)
                        headPopup.mask:SetActive(false)
                    end
                )
                -- 点击详情,关闭头像详情
                self.viewUnityNode:AddClick(
                    headPopup.headInfobg,
                    function()
                        headPopup.headInfobg:SetApctive(false)
                        headPopup.mask:SetActive(false)
                    end
                )

                headPopup.mask:Show(true)
                headPopup.mask.transform.size = Vector2(3000, 3000)
                headPopup.mask.transform:AddComponent(typeof(Image)).color = Color(0, 0, 0, 0)
                -- if viewChairID > 1 then
                --     headPopup.headInfobg.transform.localPosition = userInfoBgPos[viewChairID]
                -- end
                headPopup.headInfobg.transform.localScale = Vector3(0.5, 0.5, 1)
                self.viewUnityNode:RunAction(headPopup.mask, {"fadeTo", 30, 0.3})
                self.viewUnityNode:RunAction(headPopup.headInfobg, {"scaleTo", 1, 1, 0.3, ease = EOutBack})
            end
        )
    end
    self.headPopup = headPopup
end

function PlayerView:sendDonate(item)
    -- 1：鲜花    2：啤酒    3：鸡蛋    4：拖鞋
    -- 8：献吻    7：红酒    6：大便    5：拳头
    local chairID = self.player.chairID

    local msgDonate = pkproto2.MsgDonate()
    msgDonate.toChairID = chairID
    msgDonate.itemID = item
    self.player.room:sendMsg(pokerfaceProto.OPDonate, msgDonate)
end

function PlayerView:onClickDonateBtn(item, isOn)
    -- if 钻石不足  （您的钻石不足无法使用此道具） else
    local dd = 1
    if item == 2 or item == 4 then
        dd = 3
    elseif item == 6 or item == 8 then
        dd = 5
    elseif item == 5 or item == 7 then
        dd = 10
    end

    local propNum = 0
    -- 使用道具配置中的价格
    local prop = self:getRoomProp(item)
    if prop ~= nil then
        dd = prop["diamond"]
        propID = prop["propID"]
        propNum = g_dataModule:GetPackagePropNum(propID)
    end

    if propNum == 0 and self.player.room.myPlayer.diamond < dd then
        dfCompatibleAPI:showTip("您的钻石不足无法使用此道具")
        return
    end

    if isOn or propNum > 0 then
        self:sendDonate(item)
    else
        --self.headPopup.headInfobg:SetActive(false)
        local str = "您是否确认消耗钻石来使用此道具"
        local okFunc = function()
            --确认操作
            self:sendDonate(item)
            --self.headPopup.headInfobg:SetActive(false)
        end
        local noFunc = function()
            --取消操作
            self.headPopup.headInfobg:SetActive(true)
        end
        local dialog = {
            content = str,
            ignoreCloseBtn = true,
            btnData = {
                {callback = okFunc, text = "是"},
                {callback = noFunc, text = "否"}
            }
        }
        g_commonModule:ShowDialog(dialog)
    end
end

function PlayerView:kickoutPlayer()
    if self.viewChairID == 1 then
        logger.debug(" can not kickout self")
        return
    end

    msg = "踢出的玩家10分钟内不能再加入本房间，是否确认踢出该玩家？"
    dfCompatibleAPI:showMessageBox(
        msg,
        function()
            local room = self.player.room
            local msg2 = mjproto2.MsgKickout()
            msg2.victimUserID = self.player.userID
            room:sendMsg(mjproto.OPKickout, msg2)
        end,
        function()
            --nothing to do
        end
    )

end

------------------------------------
--从根节点上隐藏所有
------------------------------------
function PlayerView:hideAll()
    self.tilesRoot:SetActive(false)
    self.head.root:SetActive(false)
    self.readyIndicator.visible = false
    self.headPopup.headInfobg:SetActive(false)
end

------------------------------------
--新的一手牌开始，做一些清理后再开始
------------------------------------
function PlayerView:resetForNewHand()
    self:hideHands()
    -- self:hideFlowers()
    -- self:hideLights()
    -- self:clearDiscardable()
    -- self:hideDiscarded()
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

--清理特效列表
-- function PlayerView:cleanEffectObjLists()
--     if self.effectObjLists then
--         local len = #self.effectObjLists
--         if len > 0 then
--             for i = 1 , len do
--                 GameObject.Destroy(self.effectObjLists[i].gameObject)
--             end
--         end
--     end
--     self.effectObjLists = {}
-- end

------------------------------------
--隐藏打出去的牌列表
------------------------------------
function PlayerView:hideDiscarded()
    local discards = self.discards
    for _, d in ipairs(discards) do
        d:SetActive(false)
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
    logger.debug("+ +++++++++++++++++  ",self.hands)
    -- for _, h in ipairs(self.hands) do
    --     h.visible = false
    -- end
    if self.viewChairID == 1 then
        for i = 1, 16 do
            self.hands[i].visible = false
        end
    end
    --TODO: 取消所有听牌、黄色遮罩等等
    --self.na:SetActive(false)

    --面子牌组也隐藏
    -- for _,m in ipairs(self.meldViews) do
    --     if m.root then
    --         m.root:SetActive(false)
    --     end
    -- end
end

------------------------------------------
--隐藏花牌列表
------------------------------------------
function PlayerView:hideFlowers()
    -- for _, f in ipairs(self.flowers) do
    --     f:SetActive(false)
    -- end
    -- self.head.HuaNode:SetActive(false)
end

------------------------------------------
--显示花牌，注意花牌需要是平放的
------------------------------------------
function PlayerView:showFlowers()
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
        d:SetActive(true)
        j = j + 1
    end
    --这里的 dianShu 只在 单个跟对的时候  有用
    --return dianShu
end

------------------------------------
--把打出的牌放大显示
------------------------------------
function PlayerView:enlargeDiscarded(discardTileId, waitDiscardReAction)
    local discardTips = self.discardTips
    local discardTipsTile = self.discardTipsTile
    local discardTipsYellow = self.discardTipsYellow

    tileMounter:mountTileImage(discardTipsTile, discardTileId)
    discardTipsTile:SetActive(true)
    discardTips:SetActive(true)

    if waitDiscardReAction then
        self.player.waitDiscardReAction = true
        discardTipsYellow:SetActive(true)
    else
        discardTipsYellow:SetActive(false)
        --ANITIME_DEFINE.OUTCARDTIPSHOWTIME --> 0.7
        self.viewUnityNode:DelayRun(
            0.7,
            function()
                discardTipsTile:SetActive(false)
                discardTips:SetActive(false)
            end
        )
    end
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
--显示面子牌组
---------------------------------------------
function PlayerView:showMelds()
end

------------------------------------------
--显示面子牌组，暗杠需要特殊处理，如果是自己的暗杠，
--则明牌显示前3张，第4张暗牌显示（以便和明杠区分）
--如果是别人的暗杠，则全部暗牌显示
------------------------------------------
function PlayerView:mountMeldImage(meldView, msgMeld)
end

--单独用于结算界面的面子牌组显示
function PlayerView:mountResultMeldImage(meldView, msgMeld)
end

function PlayerView:mountConcealedKongTileImage(t, tileID)
    --local player = self.player
    --tileID == pokerfaceProto.pokerfaceProto.enumTid_MAX表示该牌需要暗牌显示
    if tileID == pokerfaceProto.enumTid_MAX then
        tileMounter:mountMeldDisableImage(t, tileID, self.viewChairID)
    else
        tileMounter:mountMeldEnableImage(t, tileID, self.viewChairID)
    end
end

function PlayerView:hideFlowerOnHandTail()
    --self.na:SetActive(false)
end

function PlayerView:showFlowerOnHandTail(flower)
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
        h:SetActive(isShow)
        handsClickCtrls[i].tileID = cardsOnHand[j]
        j = j + 1
    end

    if cardCountOnHand < 4 then
        self:showGaoJing(cardCountOnHand)
    end
end

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

    --先显示所有melds面子牌组
    --self:showMelds()

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
    if not discardAble then
        --logger.debug(" clear discardable.."..debug.traceback())
        self:clearDiscardable()
        --把听牌标志隐藏
        self:hideTing()
    end

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
                self:setGray(self.handsClickCtrls[i].h)
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

    if not player:isMe()then
        return
    end
     --播放选牌音效
    local handsClickCtrls = self.handsClickCtrls
    dfCompatibleAPI:soundPlay("effect/effect_xuanpai")

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
--隐藏听牌标志
-------------------------------------------------
function PlayerView:hideTing()
    for i = 1, 16 do
        local clickCtrl = self.handsClickCtrls[i]
        if clickCtrl ~= nil and clickCtrl.t ~= nil then
            clickCtrl.t:SetActive(false)
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
        -- local clickCtrl = self.handsClickCtrls[i]
        -- local originPos = self.handsOriginPos[i]
        -- local h = clickCtrl.h
        -- h.transform.localPosition = Vector3(originPos.x, originPos.y, 0)
        -- clickCtrl.clickCount = 0
        -- self:clearGray(h)
        end
    end
end

-------------------------------------------------
--把手牌往上移动30的单位距离
-------------------------------------------------
function PlayerView:moveHandUp(index)
    local originPos = self.handsOriginPos[index]
    local h = self.handsClickCtrls[index].h
    h.position.y = originPos.position.y + 30
    -- h.transform.localPosition = Vector3(originPos.x, originPos.y + 30, 0)
    self.handsClickCtrls[index].clickCount = 1
    --self:setGray(h)
    self:clearGray(h)
end
-------------------------------------------------
--把手牌还原位置
-------------------------------------------------
function PlayerView:restoreHandUp(index)
    local originPos = self.handsOriginPos[index]
    local h = self.handsClickCtrls[index].h
    h.position.y = originPos.position.y
    -- h.transform.localPosition = Vector3(originPos.x, originPos.y, 0)
    self.handsClickCtrls[index].clickCount = 0
    self:clearGray(h)
end
-------------------------------------------------
--让所有的手牌都不可以点击
-------------------------------------------------
function PlayerView:clearDiscardable()
    if self.player.isRichi then
        --如果是听牌状态下，则不再把牌弄回白色（让手牌一直是灰色的）
        return
    end
    for i = 1, 16 do
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

----------------------------------------------------------
--动画播放，吃
----------------------------------------------------------
function PlayerView:playChowResultAnimation()
    local player = self.player

    --播放特效
    self:playerOperationEffect(dfConfig.EFF_DEFINE.SUB_ZI_CHI)

    -- if player:isMe() then
    --     local waitCo = coroutine.running()
    --     --目标组牌
    --     local melds = player.melds
    --     local opMeld = melds[#melds]

    --     for i = 0, 2 do
    --         local node = self.operationAnimNodes[i + 1]
    --         tileMounter:mountMeldEnableImage(node, opMeld.tile1 + i, self.viewChairID)
    --     end
    --     self.operationAnimNodes[4]:SetActive(false)

    --     local targetMeld = self.meldViews[#melds]
    --     self:playerOperationAnimation(targetMeld.root, waitCo)

    --     coroutine.yield()
    -- end
end

----------------------------------------------------------
--动画播放，碰
----------------------------------------------------------
function PlayerView:playPongResultAnimation()
    local player = self.player

    --播放特效
    self:playerOperationEffect(dfConfig.EFF_DEFINE.SUB_ZI_PENG)

    -- if player:isMe() then
    --     local waitCo = coroutine.running()
    --     --目标组牌
    --     local melds = player.melds
    --     local opMeld = melds[#melds]

    --     for i = 1, 3 do
    --         local node = self.operationAnimNodes[i]
    --         tileMounter:mountMeldEnableImage(node, opMeld.tile1, self.viewChairID)
    --     end
    --     self.operationAnimNodes[4]:SetActive(false)

    --     local targetMeld = self.meldViews[#melds]
    --     self:playerOperationAnimation(targetMeld.root, waitCo)

    --     coroutine.yield()
    -- end
end

----------------------------------------------------------
--动画播放，明杠
----------------------------------------------------------
function PlayerView:playExposedKongResultAnimation()
    local player = self.player

    --播放特效
    self:playerOperationEffect(dfConfig.EFF_DEFINE.SUB_ZI_GANG)

    -- if player:isMe() then
    --     local waitCo = coroutine.running()
    --     --目标组牌
    --     local melds = player.melds
    --     local opMeld = melds[#melds]

    --     for i = 1, 4 do
    --         local node = self.operationAnimNodes[i]
    --         tileMounter:mountMeldEnableImage(node, opMeld.tile1, self.viewChairID)
    --     end
    --     self.operationAnimNodes[4]:SetActive(true)

    --     local targetMeld = self.meldViews[#melds]
    --     self:playerOperationAnimation(targetMeld.root, waitCo)

    --     coroutine.yield()
    -- end
end

----------------------------------------------------------
--动画播放，暗杠
----------------------------------------------------------
function PlayerView:playConcealedKongResultAnimation()
    local player = self.player

    --播放特效
    self:playerOperationEffect(dfConfig.EFF_DEFINE.SUB_ZI_GANG)

    -- if player:isMe() then
    --     local waitCo = coroutine.running()
    --     --目标组牌
    --     local melds = player.melds
    --     local opMeld = melds[#melds]

    --     local node = nil
    --     for i = 1, 3 do
    --         local node = self.operationAnimNodes[i]
    --         tileMounter:mountMeldEnableImage(node, opMeld.tile1, self.viewChairID)
    --     end

    --     local node = self.operationAnimNodes[4]
    --     tileMounter:mountMeldDisableImage(node, opMeld.tile1, self.viewChairID)
    --     self.operationAnimNodes[4]:SetActive(true)

    --     local targetMeld = self.meldViews[#melds]
    --     self:playerOperationAnimation(targetMeld.root, waitCo)

    --     coroutine.yield()
    -- end
end

----------------------------------------------------------
--动画播放，加杠（效果表现和明杠一样）
----------------------------------------------------------
function PlayerView:playTriplet2KongResultAnimation()
    self:playExposedKongResultAnimation()
end
--不要动画并等待
function PlayerView:playSkipAnimation()
    --local waitCo = coroutine.running()

    self:playerOperationEffectWhitGZ(dfConfig.EFF_DEFINE.SUB_GUANZHANG_BUYAO, "buyao")

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
--播放补花效果，并等待结束
----------------------------------------------------------
function PlayerView:playDrawFlowerAnimation()
    --self:playerOperationEffect(EFF_DEFINE.SUB_ZI_BUHUA)
    --local waitCo = coroutine.running()

    --Sound.Play("effect_paijukaishi")
    --Animator.Play(EFF_DEFINE.SUB_ZI_BUHUA, nil, nil)
    --self:playerOperationEffect(EFF_DEFINE.SUB_ZI_BUHUA)
    --coroutine.yield()
    local waitCo = coroutine.running()
    local effectObj =
        Animator.Play(dfConfig.PATH.EFFECTS .. dfConfig.EFF_DEFINE.SUB_ZI_BUHUA .. ".prefab", self.viewUnityNode.order)
    effectObj:SetParent(self.operationTip)
    effectObj.localPosition = Vector3(0, 0, 0)

    self.player:playSound("hua")
    self.viewUnityNode:DelayRun(
        0.8,
        function()
            local flag, msg = coroutine.resume(waitCo)
            if not flag then
                logError(msg)
                return
            end
        end
    )

    coroutine.yield()
end

----------------------------------------------------------
--动画播放
----------------------------------------------------------
-- function PlayerView:playerOperationAnimation(target, waitCo)
--     --初始化动画初始位置
--     self.operationAnim.position = self.operationAnimPosition
--     self.operationAnim:SetParent(target.parent)
--     self.operationAnim:SetActive(true)
--     self.viewUnityNode:DelayRun(0.8, function()
--         actionMgr:MoveTo(self.operationAnim, target.localPosition, 0.3, function()
--             self.operationAnim:SetActive(false)
--             local flag, msg =  coroutine.resume(waitCo)
--             if not flag then
--                 logError(msg)
--                 return
--             end
--         end)
--     end)
-- end

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
    local effectObj = Animator.Play(dfConfig.PATH.EFFECTS_GZ .. effectName .. ".prefab", self.viewUnityNode.order+1)

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
--起手听特效播放
----------------------------------------------------------
function PlayerView:playReadyHandEffect()
    self:playerOperationEffect(dfConfig.EFF_DEFINE.SUB_ZI_TING)
end

--设置灰度
function PlayerView:setGray(btn)
    -- if btn ~= nil then
    -- 	local hImg = btn:Find("hua")
    -- 	local imageA = btn:GetComponent("Image")
    -- 	local imageB = hImg:GetComponent("Image")
    --     imageA.color = Color(120/255, 122/255, 122/255, 1)
    --     imageB.color = Color(120/255, 122/255, 122/255, 1)
    -- end

    if btn ~= nil then
        local hImg = btn:Find("gray")
        hImg:SetActive(true)
    end
end

--恢复灰度
function PlayerView:clearGray(btn)
    -- if btn ~= nil then
    -- 	local hImg = btn:Find("hua")
    -- 	local imageA = btn:GetComponent("Image")
    --     local imageB = hImg:GetComponent("Image")
    --     imageA.color = Color(1, 1, 1, 1)
    --     imageB.color = Color(1, 1, 1, 1)
    -- end

    if btn ~= nil then
        local hImg = btn:Find("gray")
        hImg:SetActive(false)
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

--设置面子牌的方向
function PlayerView:setMeldTileDirection(tileObj, dir)
    if dir > 0 then
        local image = tileObj.transform:Find("direction")

        if image then
            image:SetImage("GameModule/GuanZhang/_AssetsBundleRes/image/ts_dui.png")
            image:SetActive(true)

            -- local color = Color(255,255,255,0.75)
            -- image.color = color

            if dir == 1 then
                image.localEulerAngles = Vector3(0, 0, 180)
            elseif dir == 2 then
                image.localEulerAngles = Vector3(0, 0, -90)
            elseif dir == 3 then
                -- -- 如果是自己,就不翻转,如果是当前对面,则翻转
                -- if self.viewChairID == 1 then
                --      image.localEulerAngles = Vector3(0, 0, 0)
                -- else
                --      image.localEulerAngles = Vector3(0, 0, 180)
                -- end
                image.localEulerAngles = Vector3(0, 0, 0)
            elseif dir == 4 then
                image.localEulerAngles = Vector3(0, 0, 90)
            end
        end
    end
end

-------------------------------------------------
---- 根据道具的序号（道具槽位）从道具配置中获取对应的道具
------------------------------------------------
function PlayerView:getRoomProp(index)
    local player = self.player
    local room = player.room
    return room:getPropCfg(index)
end

-------------------------------------------------
---- 根据道具配置获取对应的道具名称
------------------------------------------------
function PlayerView:getPropIconName(prop)
    local player = self.player
    local room = player.room
    return room:getPropIconName(prop)
end

-------------------------------------------------
---- 更新用户道具数量
------------------------------------------------
function PlayerView:updatePropNum(index)
    local viewChairID = self.viewChairID
    -- 点开自己的头像不更新，因为没有道具
    if viewChairID == 1 then
        return
    end

    local donateBtn = self.viewUnityNode.donateBtns[index]
    local propNum = donateBtn:Find("ItemNum")
    local prop = self:getRoomProp(index)
    if prop ~= nil then
        local propID = prop["propID"]
        local num = g_dataModule:GetPackagePropNum(propID)
        logger.debug("num"..tostring(num)..", propID:"..tostring(propID))
        if num and num ~=0 then
            propNum:SetActive(true)
            local propNumText = propNum:Find("Text")
            propNumText.text = "免费"..tostring(num).."次"
        else
            propNum:SetActive(false)
        end
    end
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
