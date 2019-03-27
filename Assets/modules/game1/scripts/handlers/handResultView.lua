--[[
    显示一手牌结束后的得分结果
]]
local HandResultView = {}
HandResultView.VERSION = "1.0"

local dfPath = "GuanZhang/Script/"
local tmpPath = "AccComponent.Script."
local tileMounter = require(dfPath .. "dfMahjong/tileImageMounter")

local bit = require(dfPath .. "dfMahjong/bit")
local DfHuaDunView = require(dfPath .. "dfMahjong/dfHuaDunView")
local Loader = require(dfPath .. "dfMahjong/spriteLoader")
local dfConfig = require(dfPath .. "dfMahjong/dfConfig")
local dfCompatibleAPI = require(dfPath .. "dfMahjong/dfCompatibleAPI")
require (dfPath.."Proto/game_pokerface_rf_pb")
local pokerfacerf = game_pokerface_rf_pb
local mt = {__index = HandResultView}
local Key = "handResultView"
function HandResultView:new(room, viewObj, waitCo)
    local handResultView = {}
    setmetatable(handResultView, mt)
    handResultView.waitCo = waitCo
    handResultView.room = room
    --结算数据
    handResultView.msgHandOver = room.msgHandOver

    --结果是以messagebox来显示
    handResultView.unityViewNode = viewObj -- room:openMessageBoxFromDaFeng(config)

    local uiDepth = viewObj:GetComponent("UIDepth")
    handResultView.canvasOrder = uiDepth.canvasOrder

    --排序players
    local players2 = room.players
    local players = {}
    local i = 1
    for _, p in pairs(players2) do
        players[i] = p
        i = i + 1
    end
    table.sort(
        players,
        function(x, y)
            return x.playerView.viewChairID < y.playerView.viewChairID
        end
    )
    handResultView.players = players

    local unityViewNode = handResultView.unityViewNode

    --订阅按钮事件
    unityViewNode:AddClick(
        "AgainButton",
        function()
            handResultView:onAgainButtonClick()
        end
    )
    unityViewNode:AddClick(
        "ShareButton",
        function()
            handResultView:onShareButtonClick()
        end
    )
    unityViewNode:AddClick(
        "CloseButton",
        function()
            handResultView:onCloseButtonClick()
        end
    )
    --unityViewNode:AddClick("HuDunButton", function() handResultView:onHuDunButtonClick() end)
    -- self:AddLongPressClick("HuDunButton", function()
    --     handResultView:onCloseButtonClick()
    -- end, 1)
    --tips‘按住不放可查看桌面花牌和墩子’
    -- local huDunButton = unityViewNode:FindChild("HuDunButton")
    -- huDunButton.onDown = function()
    --     --unityViewNode:SetActive(false)
    --     if handResultView.huadunTip.activeSelf then
    --         UnityEngine.PlayerPrefs.SetString(Key, "true")
    --         handResultView.huadunTip:SetActive(false)
    --     end
    --     handResultView:showOrHideSelf(false)
    -- end
    -- huDunButton.onUp = function()
    --     --unityViewNode:SetActive(true)
    --     handResultView:showOrHideSelf(true)
    -- end


    -- ios提审屏蔽
    if g_ModuleMgr:GetModule("ConfigModule"):IsIosAudit() then
        unityViewNode:FindChild("AgainButton").localPosition = Vector3(0, -274, 0)

        unityViewNode:FindChild("ShareButton"):SetActive(false)
    end

    if room:isReplayMode() then
        unityViewNode:FindChild("AgainButton"):SetActive(false)
        unityViewNode:FindChild("ShareButton"):SetActive(false)
        unityViewNode:FindChild("CloseButton"):SetActive(false)
        unityViewNode:FindChild("HuDunButton"):SetActive(false)
    end

    --初始化View
    handResultView:initAllView()
    --更新数据
    handResultView:updateAllData()
    return handResultView
end

function HandResultView:showOrHideSelf(isShow)
    local a = 0
    if isShow then
        a = 1
    end
    local images = self.unityViewNode.transform:GetComponentsInChildren(typeof(UnityEngine.UI.Image))
    local Len = images.Length
    if Len > 0 then
        for idx = 0, Len - 1 do
            local r = images[idx].color.r
            local g = images[idx].color.g
            local b = images[idx].color.b
            local color = Color(r, g, b, a)
            images[idx].color = color
        end
    end
    local texts = self.unityViewNode.transform:GetComponentsInChildren(typeof(UnityEngine.UI.Text))
    Len = texts.Length
    if Len > 0 then
        for idx = 0, Len - 1 do
            local r = texts[idx].color.r
            local g = texts[idx].color.g
            local b = texts[idx].color.b
            local color = Color(r, g, b, a)
            texts[idx].color = color
        end
    end
    local rawimages = self.unityViewNode.transform:GetComponentsInChildren(typeof(UnityEngine.UI.RawImage))
    Len = rawimages.Length
    if Len > 0 then
        for idx = 0, Len - 1 do
            local r = rawimages[idx].color.r
            local g = rawimages[idx].color.g
            local b = rawimages[idx].color.b
            local color = Color(r, g, b, a)
            rawimages[idx].color = color
        end
    end

    local outlines = self.unityViewNode.transform:GetComponentsInChildren(typeof(UnityEngine.UI.Outline))
    Len = outlines.Length
    if Len > 0 then
        for idx = 0, Len - 1 do
            local r = outlines[idx].color.r
            local g = outlines[idx].color.g
            local b = outlines[idx].color.b
            local color = Color(r, g, b, a)
            outlines[idx].color = color
        end
    end

    if isShow then
        self.effect.localPosition = Vector3(1.6, 0.8, 0)
        self.bgImage.color = Color(0, 0, 0, 0.47)
    else
        self.effect.localPosition = Vector3(1.6, 2000, 0)
    end
end

-- function HandResultView:orderAdd(view)
--     local canvas = view.transform:GetComponentsInChildren(typeof(UnityEngine.Canvas))
--     local Len = canvas.Length
--     if Len > 0 then
--         for idx = 0, Len - 1  do
--             canvas[idx].sortingOrder = self.canvasOrder + 2
--         end
--     end
-- end

-------------------------------------------
--更新房间相关数据
-------------------------------------------
function HandResultView:updateRoomData()
    --背景（输还是赢）
    --endType == enumHandOverType_None 表示流局 也就是没有人胡牌
    --if self.msgHandOver.endType ~= pokerfacerf.enumHandOverType_None then
        if self.room:me().score.score > 0 then
            --self.bgImageWin:SetActive(true)
            local effobj =
                Animator.PlayLoop(
                dfConfig.PATH.EFFECTS_GZ .. dfConfig.EFF_DEFINE.SUB_JIEMIAN_YING .. ".prefab",
                self.canvasOrder
            )
            effobj:SetParent(self.unityViewNode.transform, false)
            effobj.localPosition = Vector3(1.6, 0.8, 0)
            self.effect = effobj
        else
            -- self.bgImageLose:SetActive(true)
            local effobj =
                Animator.PlayLoop(
                dfConfig.PATH.EFFECTS_GZ .. dfConfig.EFF_DEFINE.SUB_JIEMIAN_SHU .. ".prefab",
                self.canvasOrder
            )
            effobj:SetParent(self.unityViewNode.transform, false)
            effobj.localPosition = Vector3(1.6, 0.8, 0)
            self.effect = effobj
        end
    -- else
    --     self.bgImageLose:SetActive(true)
    --     local effobj =
    --         Animator.PlayLoop(
    --         dfConfig.PATH.EFFECTS_GZ .. dfConfig.EFF_DEFINE.SUB_JIEMIAN_HUANGZHUANG .. ".prefab",
    --         self.canvasOrder
    --     )
    --     effobj:SetParent(self.unityViewNode.transform, false)
    --     effobj.localPosition = Vector3(1.6, 0.8, 0)
    --     self.effect = effobj
    -- end
    --self:orderAdd(self.effect)

    --日期时间
    local date
    if not self.room:isReplayMode() then
        date = os.date("%Y-%m-%d %H:%M")
    else
        local startTime = self.room.dfReplay.msgHandRecord.endTime
        date = os.date("%Y-%m-%d %H:%M", startTime * 60)
    end

    self.textTime.text = date
    --房间信息
    if self.room.roomInfo == nil then
        return
    end

    --local rule = ""
    local roomNumber = self.room.roomNumber
    if roomNumber == nil then
        roomNumber = ""
    end
    self.textRoomNumber.text = "房号:" .. tostring(roomNumber)

    local handNum = self.room.handNum
    local handStartted = self.room.handStartted
    local handNum = self.room.handNum
    if handNum ~= nil and handStartted ~= nil then
        self.handAmount.text = "局数: "..tostring(handStartted).."/"..tostring(handNum)
    end
    local roomConfig = self.room.roomInfo.config
    if roomConfig ~= nil and roomConfig ~= "" then
        print("roomConfig : "..roomConfig)
        local config = Json.decode(roomConfig)
        if config.payType ~= nil then
            self.payType.text = "付费:房主支付"
            if config.payType == 1 then
                self.payType.text = "付费:钻石平摊"
            end
        end
    end

end

-------------------------------------------
--更新玩家基本信息
-------------------------------------------
function HandResultView:updatePlayerInfoData(player, c)
    --名字
    local name = player.nick
    local userID = player.userID
    if name == nil or name == "" then
        name = userID
    end
    c.textName.text = name
    --房主
    if player.userID == self.room.ownerID then
        c.imageRoom:SetActive(true)
    end
    --头像
    if player.sex == 1 then
        c.imageIcon.sprite = dfCompatibleAPI:loadDynPic("playerIcon/boy_img")
    else
        c.imageIcon.sprite = dfCompatibleAPI:loadDynPic("playerIcon/girl_img")
    end
    if player.headIconURI ~= nil and player.headIconURI ~= "" then
        -- player.playerView:getPartnerWeixinIcon(
        --     player.headIconURI,
        --     function(texture)
        --         c.imageIcon.transform:SetImage(texture)
        --     end
        -- )
        local tool = g_ModuleMgr:GetModule(ModuleName.TOOLLIB_MODULE)
        tool:SetUrlImage(c.imageIcon.transform,player.headIconURI)
    else
        print("player.headIconURI is nill")
    end

    if player.avatarID ~= nil and player.avatarID ~= 0 then
        c.headBox.transform:SetImage(string.format("Component/CommonComponent/Bundle/image/box/bk_%d.png", player.avatarID))
        c.headBox.transform:GetComponent("Image"):SetNativeSize()
        c.headBox.transform.localScale = Vector3(0.8, 0.8, 1)
    end
end

-------------------------------------------
--更新麻将牌数据
-------------------------------------------
function HandResultView:updatePlayerTileData(player, c)
    local melds = player.melds --落地牌组
    local cardsOnHand = player.cardsOnHand --玩家手上的牌（暗牌）排好序的

    --手牌
    local cardCountOnHand = #cardsOnHand
    if cardCountOnHand > 0 then
        for i = 1, cardCountOnHand do
            local tiles = cardsOnHand[i]
            local oCardObj = c.cards:Find(tostring(i))
            tileMounter:mountTileImage(oCardObj, tiles)
            oCardObj:SetActive(true)
        end
        c.textPlayerScore.text = "剩余手牌:" .. tostring(cardCountOnHand)
        c.textPlayerScore.transform:SetActive(true)
    end
end
-------------------------------------------
--更新显示数据
-------------------------------------------
function HandResultView:updateAllData()
    local number = 1
    -- local players2 = self.room.players
    -- local players = {}
    -- local i = 1
    -- for _,p in pairs(players2) do
    --     players[i] = p
    --     i = i+1
    -- end

    -- table.sort(players, function(x,y) return x.playerView.viewChairID < y.playerView.viewChairID end)

    --整个房间数据
    self:updateRoomData()

    for _, player in ipairs(self.players) do
        --local melds = player.melds --落地牌组
        --local cardsOnHand = player.cardsOnHand --玩家手上的牌（暗牌）排好序的
        --local chairID = player.chairID
        local c = self.contentGroup[number]
        c.textCount:SetActive(true)
        c.group:SetActive(true)
        local isMe = player == self.room:me()
        --玩家基本信息
        self:updatePlayerInfoData(player, c)
        local myScore = 0
        --endType == enumHandOverType_None 表示流局 也就是没有人胡牌
        --if self.msgHandOver.endType ~= pokerfacerf.enumHandOverType_None then
            local playerScores = player.score --这是在 handleMsgHandOver里面保存进去的
            myScore = playerScores.score
            --包牌
            if playerScores.winType == pokerfacerf.enumHandOverType_Chucker then
                c.textChucker:SetActive(true)
            end
        --end
        --牌
        self:updatePlayerTileData(player, c)

        --分数
        if myScore > 0 then
            c.textCountT.text = "+" .. tostring(myScore)
            c.textCount:SetActive(true)
            c.textCountLose:SetActive(false)
            -- c.textName.transform:SetActive(false)
            self:showWin(c)
        else
            c.textCountLoseT.text = tostring(myScore)
            c.textCountLose:SetActive(true)
            c.textCount:SetActive(false)
        end
        number = number + 1
    end
end
--显示赢标志
function HandResultView:showWin(c)
    local effobj =
        Animator.PlayLoop(
        dfConfig.PATH.EFFECTS_GZ .. dfConfig.EFF_DEFINE.SUB_JIEMIAN_WIN .. ".prefab",
        self.canvasOrder
    )
    effobj:SetParent(c.group.transform, false)
    effobj.localPosition = c.winImagePos.localPosition --Vector3(1.6, 0.8, 0)
end

-------------------------------------------
--初始化界面
-------------------------------------------
function HandResultView:initAllView()
    --背景
    self.bgImage = self.unityViewNode.transform:SubGet("BGImage", "Image") --透明背景
    --self.bgImageWin = self.unityViewNode.transform:Find("BGImageWin") --赢
    --self.bgImageLose = self.unityViewNode.transform:Find("BGImageLose") --输
    -- self.bgImageWin:SetActive(false)
    -- self.bgImageLose:SetActive(false)
    --日期时间
    self.textTime = self.unityViewNode.transform:Find("TextTime")
    --房间信息
    --self.textRule = self.unityViewNode.transform:Find("Content/TextRule")
    self.textRoomNumber = self.unityViewNode.transform:Find("TextRoomNumber")
    --付费
    self.payType = self.unityViewNode.transform:Find("PayType")
    --局数
    self.handAmount = self.unityViewNode.transform:Find("HandAmount")
    --按钮提示
    -- self.huadunTip = self.unityViewNode.transform:Find("huadunTip")

    -- local isCheck = UnityEngine.PlayerPrefs.GetString(Key)
    -- if isCheck == "true" or self.room:isReplayMode() then
    --     self.huadunTip:SetActive(false)
    -- else
    --     self.huadunTip:SetActive(true)
    -- end

    local contentGroup = {}
    for var = 1, 3, 1 do
        local contentGroupData = {}
        local group = self.unityViewNode.transform:Find("Content/Group/" .. var)
        contentGroupData.group = group
        --头像
        contentGroupData.imageIcon = group:SubGet("ImageIcon", "Image")
        contentGroupData.headBox = group:SubGet("ImageIcon/Image", "Image")
        --房主标志
        contentGroupData.imageRoom = group:Find("ImageRoom")
        contentGroupData.imageRoom:SetActive(false)
        --牌详情
        contentGroupData.cards = group:Find("Cards")
        --名字
        contentGroupData.textName = group:SubGet("TextName", "Text")
        --分数为正的时候显示
        contentGroupData.textCount = group:Find("Count/TextCountI")
        contentGroupData.textCountT = group:SubGet("Count/TextCountI", "Text")
        contentGroupData.textCountT.text = "0"
        contentGroupData.textCount:SetActive(false)
        --分数为负的时候显示
        contentGroupData.textCountLose = group:Find("Count/TextCountILose")
        contentGroupData.textCountLoseT = group:SubGet("Count/TextCountILose", "Text")
        contentGroupData.textCountLoseT.text = "0"
        contentGroupData.textCountLose:SetActive(true)
        --手牌
        contentGroupData.cards = group:Find("Cards")
        --赢标志的位置
        contentGroupData.winImagePos = group:Find("WinImagePos")
        --剩余牌数
        contentGroupData.textPlayerScore = group:SubGet("TextPlayerScore", "Text")
        --包牌
        contentGroupData.textChucker = group:Find("TextChucker")

        --保存userID
        contentGroupData.userID = ""

        --logError("initAllView var : "..var)
        contentGroup[var] = contentGroupData

        group:SetActive(false)
    end
    self.contentGroup = contentGroup
end

-------------------------------------------
--玩家点击“继续”按钮，注意如果牌局结束，此按钮
--是“大结算”
-------------------------------------------
function HandResultView:onAgainButtonClick()
    self.unityViewNode:Destroy()
    if self.msgHandOver.continueAble then
        self.room.host:sendPlayerReadyMsg()
    else
    end

    self.room.handResultView = nil
    self.room:completedWait()
end

-------------------------------------------
--玩家点击分享按钮
-------------------------------------------
function HandResultView:onShareButtonClick()
    --TODO: 显示分享UI
    --隐藏掉特效
    -- if self.effect then
    -- 	self.effect:Hide()
    -- end
    --OnlineLogic.ShowShareView()
    --ViewManager.OpenMessageBoxWithOrder("ShareView", 5, 9)
    --self.room:openMessageBoxFromDaFeng("ShareView", 5, 9)
    local shareMudule = g_ModuleMgr:GetModule(ModuleName.SHARE_MODULE)
    shareMudule:ShareGameResult(1, "", 32, 1)
    local u8sdk = U8SDK.SDKWrapper.Instance
    local fSuccess = function(data)
        local tool = g_ModuleMgr:GetModule(ModuleName.TOOLLIB_MODULE)
        tool:SendShareRecord(2)
    end
    u8sdk.OnShareSuccess = fSuccess
end

-------------------------------------------
--玩家点击返回按钮
-------------------------------------------
function HandResultView:onCloseButtonClick()
    -- local flag, msg = coroutine.resume(self.waitCo)
    -- if not flag then
    --     logError(msg)
    -- 	return
    -- end
    self.unityViewNode:Destroy()
    self.room.handResultView = nil

    if self.msgHandOver.continueAble then
        self.room.host:sendPlayerReadyMsg()
    else
    end

    self.room:completedWait()
end

-------------------------------------------
--玩家点击显示花牌墩子详情按钮
-------------------------------------------
function HandResultView:onHuDunButtonClick()
    local viewModule = g_ModuleMgr:GetModule(ModuleName.VIEW_MODULE)
    -- local viewObj = viewModule:OpenMsgBox({
    --     luaPath = dfPath .. "View/DFHuaDunView",
    --     resPath = "GameModule/GuanZhang/_AssetsBundleRes/prefab/bund2/DFHuaDunView.prefab"
    -- })
    local viewObj =
        viewModule:CreatePanel(
        {
            luaPath = dfPath .. "View/DFHuaDunView",
            resPath = "GameModule/GuanZhang/_AssetsBundleRes/prefab/bund2/DFHuaDunView.prefab",
            superClass = self.unityViewNode,
            parentNode = self.unityViewNode.transform
        }
    )
    local uiDepth = viewObj:GetComponent("UIDepth")
    if not uiDepth then
        uiDepth = viewObj:AddComponent(UIDepth)
    end
    uiDepth.canvasOrder = self.canvasOrder + 2

    local dfHuaDunView = DfHuaDunView:new(self.room, self.players, viewObj)
    self.dfHuaDunView = dfHuaDunView
    --ViewManager.OpenMessageBoxWithOrder("DFHuaDunView", self.room)
end

function HandResultView:destroy()
    self.unityViewNode:Destroy()
end

return HandResultView
