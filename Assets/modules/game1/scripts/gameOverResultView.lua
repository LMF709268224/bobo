--[[
    显示一手牌结束后的得分结果
]]
local GameOverResultView = {}
GameOverResultView.VERSION = "1.0"
local dfPath = "GuanZhang/Script/"
local tileMounter = require(dfPath .. "dfMahjong/tileImageMounter")

local bit = require(dfPath .. "dfMahjong/bit")
local Loader = require(dfPath .. "dfMahjong/spriteLoader")

local dfConfig = require(dfPath .. "dfMahjong/dfConfig")
local mt = {__index = GameOverResultView}

local dfCompatibleAPI = require(dfPath .. "dfMahjong/dfCompatibleAPI")
local configModule = g_ModuleMgr:GetModule("ConfigModule")
function GameOverResultView:new(room, viewObj, waitCo)
    local gameOverResultView = {}
    setmetatable(gameOverResultView, mt)
    gameOverResultView.waitCo = waitCo
    gameOverResultView.room = room
    --gameOverResultView.prefabName = prefabName
    --结算数据
    gameOverResultView.msgGameOver = room.msgGameOver
     --msgHandOver

    --结果是以messagebox来显示
    --gameOverResultView.unityViewNode = ViewManager.OpenMessageBox(prefabName)
    --gameOverResultView.unityViewNode = room:openMessageBoxFromDaFeng(prefabName)
    gameOverResultView.unityViewNode = viewObj -- room:openMessageBoxFromDaFeng(config)

    local uiDepth = viewObj:GetComponent("UIDepth")
    gameOverResultView.canvasOrder = uiDepth.canvasOrder

    local unityViewNode = gameOverResultView.unityViewNode

    unityViewNode:AddClick(
        "ShareButton",
        function()
            gameOverResultView:onShareButtonClick()
        end
    )
    unityViewNode:AddClick(
        "CloseButton",
        function()
            gameOverResultView:onCloseButtonClick()
        end
    )

    --gameOverResultView.nextText = unityViewNode:SubGet("AgainButton/Text", "Text")
    --TODO:如果是大结局，需要把文字改成“查看结算”
    --gameOverResultView.nextText.text = "继 续"

    if configModule:IsIosAudit()  then
        unityViewNode:FindChild("CloseButton").localPosition = Vector3(0, -274, 0)
        unityViewNode:FindChild("ShareButton"):SetActive(false)
    -- unityViewNode:FindChild("TextRoomNumber").transform.localPosition = Vector3(0, -274, 0)
    end

    --初始化View
    gameOverResultView:initAllView()
    --更新数据
    gameOverResultView:updateAllData()
    return gameOverResultView
end

-- function GameOverResultView:orderAdd(view)
--     local canvas = view.transform:GetComponentsInChildren(typeof(UnityEngine.Canvas))
--     local Len = canvas.Length
--     if Len > 0 then
--         for idx = 0, Len - 1 do
--             canvas[idx].sortingOrder = self.canvasOrder + 2
--         end
--     end
-- end
-------------------------------------------
--更新房间相关数据
-------------------------------------------
function GameOverResultView:updateRoomData()
    --牌局结算文字动效
    local effobj =
        Animator.PlayLoop(
        dfConfig.PATH.EFFECTS_GZ .. dfConfig.EFF_DEFINE.SUB_PAIJVZONGJIESUAN .. ".prefab",
        self.canvasOrder
    )
    effobj:SetParent(self.unityViewNode.transform, false)
    effobj.localPosition = Vector3(1.6, 9, 0)
    self.effect = effobj
    --self:orderAdd(effobj)
    --日期时间
    local date = os.date("%Y-%m-%d %H:%M:%S")
    self.textTime.text = date
    --房间信息
    local rule = ""
    local roomNumber = self.room.roomNumber
    --self.textRule.text = self.room:getRule()
    self.textRoomNumber.text = "房号:" .. tostring(roomNumber)
    local handStartted = self.room.handStartted
    local handNum = self.room.handNum
    local roomConfig = self.room.roomInfo.config
    if roomConfig ~= nil and roomConfig ~= "" then
        logger.debug("roomConfig : "..roomConfig)
        local config = Json.decode(roomConfig)
        if config.payType ~= nil then
            self.payType.text = "付费:房主支付"
            if config.payType == 1 then
                self.payType.text = "付费:钻石平摊"
            end
        end
    end

    if handNum ~= nil and handStartted ~= nil then
        self.handAmount.text = "局数: "..tostring(handStartted).."/"..tostring(handNum)
    end

end

-------------------------------------------
--更新玩家基本信息
-------------------------------------------
function GameOverResultView:updatePlayerInfoData(player, c)
    --名字  id
    local isMe = player == self.room:me()
    local name = player.nick
    if name == nil or name == "" then
        name = player.userID
    end
    -- if isMe then
    --     c.textName.text = "<color=#a0fd11>" .. name .. "</color>"
    --     c.textUserID.text = "<color=#a0fd11>ID:" .. player.userID .. "</color>"
    -- else
    --     c.textName.text = "<color=#61b9e2>" .. name .. "</color>"
    --     c.textUserID.text = "<color=#61b9e2>ID:" .. player.userID .. "</color>"
    -- end
    -- c.textName.text = player.userID --nick
    c.textName.text = name
    c.textUserID.text = player.userID
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
        logger.debug("player.headIconURI is nill")
    end

    if player.avatarID ~= nil and player.avatarID ~= 0 then
        c.headBox.transform:SetImage(string.format("Component/CommonComponent/Bundle/image/box/bk_%d.png",player.avatarID))
        c.headBox.transform:GetComponent("Image"):SetNativeSize()
        c.headBox.transform.localScale = Vector3(0.6,0.6,1)
    end
end

--设置相关View的字体颜色
function GameOverResultView:setTextColor(c, color)
    --胡牌、点炮、放炮、自摸次数
    c.textWin.color = color
    c.winText.color = color
end

--设置大赢家相关View
function GameOverResultView:setDYJView(c)
    --local colorSText = "#f8dd26"
    if c ~= nil then

        --大赢家动效
        local effobj =
            Animator.PlayLoop(dfConfig.PATH.EFFECTS_GZ .. dfConfig.EFF_DEFINE.SUB_DAYINGJIA .. ".prefab", self.canvasOrder)
        effobj:SetParent(c.group.transform, false)
        effobj.localPosition = c.imageWin.localPosition --Vector3(1.6, 0.8, 0)
        --self:orderAdd(effobj)
    end
end

-------------------------------------------
--更新玩家分数信息
-------------------------------------------
function GameOverResultView:updatePlayerScoreData(playerStat, c)
    local score = playerStat.score
    local chucker = playerStat.chuckerCounter
    local winSelfDrawnCounter = playerStat.winSelfDrawnCounter --赢牌局数
    c.textWin.text = tostring(winSelfDrawnCounter)
    --local colorSText = "#bbdeef"
    --local color = Color(187/255,222/255,239/255,1)
    if score > self.maxScore then
        self.maxScoreIndexs = {}
        self.maxScoreIndexs[1] = c
        self.maxScore = score
    elseif score == self.maxScore then
        local n = #self.maxScoreIndexs
        self.maxScoreIndexs[n + 1] = c
    end

    if score >= 0 then
        local add = "+"
        if score == 0 then
            add = ""
        end
        c.textCountT.text = add..tostring(score)
        c.textCountT:SetActive(true)
    else
        c.textCountLoseT.text = tostring(score)
        c.textCountLoseT:SetActive(true)
    end
end

-------------------------------------------
--更新显示数据
-------------------------------------------
function GameOverResultView:updateAllData()
    local number = 1
    --整个房间数据
    self:updateRoomData()
    local room = self.room

    --暂时保存上一个大赢家数据
    self.maxScore = 0
    self.maxScoreIndexs = {}

    if self.msgGameOver ~= nil then
        local playerStats = self.msgGameOver.playerStats
        table.sort(
            playerStats,
            function(x, y)
                return room:getPlayerByChairID(x.chairID).playerView.viewChairID <
                    room:getPlayerByChairID(y.chairID).playerView.viewChairID
            end
        )

        if playerStats ~= nil then
            for _, playerStat in ipairs(playerStats) do
                if playerStat ~= nil then
                    local c = self.contentGroup[number]
                    c.group:SetActive(true)
                    local player = self.room:getPlayerByChairID(playerStat.chairID)
                    --玩家基本信息
                    self:updatePlayerInfoData(player, c)
                    --玩家分数信息
                    self:updatePlayerScoreData(playerStat, c)
                    number = number + 1
                end
            end
            if self.maxScore > 0 and self.maxScoreIndexs ~= nil then
                for _, maxScoreIndex in ipairs(self.maxScoreIndexs) do
                    self:setDYJView(maxScoreIndex)
                end
            --self.maxScoreIndex.imageWin:SetActive(true)
            end
        end
    end
end

-------------------------------------------
--初始化界面
-------------------------------------------
function GameOverResultView:initAllView()
    --日期时间
    self.textTime = self.unityViewNode.transform:Find("TextTime")
    --房间信息
    --self.textRule = self.unityViewNode.transform:Find("TextRoomInfo")
    self.textRoomNumber = self.unityViewNode.transform:Find("TextRoomNumber")
    --局数
    self.handAmount = self.unityViewNode.transform:Find("HandAmount")
    --付费方式
    self.payType = self.unityViewNode.transform:Find("PayType")

    local contentGroup = {}
    for var = 1, 3, 1 do
        local contentGroupData = {}
        local group = self.unityViewNode.transform:Find("Content/" .. var)
        contentGroupData.group = group
        --头像
        contentGroupData.imageIcon = group:SubGet("ImageIcon", "Image")
        --头像框
        contentGroupData.headBox = group:SubGet("ImageIcon/Image", "Image")
        --房主标志
        contentGroupData.imageRoom = group:Find("ImageRoom")
        contentGroupData.imageRoom:SetActive(false)
        --大赢家标志
        contentGroupData.imageWin = group:Find("ImageWin")
        contentGroupData.imageWin:SetActive(false)
        --名字
        contentGroupData.textName = group:SubGet("TextName", "Text")
        --用户Id
        contentGroupData.textUserID = group:SubGet("TextUserID", "Text")
        --赢牌次数
        contentGroupData.textWin = group:SubGet("TextWin", "Text")
        contentGroupData.textWin.text = "0"
        contentGroupData.winText = group:SubGet("WinText", "Text")

        --分数（赢）
        contentGroupData.textCountT = group:SubGet("Count/TextCount", "Text")
        contentGroupData.textCountT.text = "0"
        --总得分
        --contentGroupData.countText = group:SubGet("Count/CountText", "Text")
        --分数（输）
        contentGroupData.textCountLoseT = group:SubGet("Count/TextCountLose", "Text")
        contentGroupData.textCountLoseT.text = "0"
        --总得分
        --contentGroupData.countTextLose = group:SubGet("Count/CountTextLose", "Text")

        contentGroup[var] = contentGroupData

        group:SetActive(false)
    end
    self.contentGroup = contentGroup
end

-------------------------------------------
--玩家点击分享按钮
-------------------------------------------
function GameOverResultView:onShareButtonClick()
    --TODO: 显示分享UI
    --ViewManager.OpenMessageBoxWithOrder("ShareView", 5, 9)
    --self.room:openMessageBoxFromDaFeng("ShareView", 5, 9)
    local shareMudule = g_ModuleMgr:GetModule(ModuleName.SHARE_MODULE)
    shareMudule:ShareGameResult(1, "", 32, 1)
    local u8sdk = U8SDK.SDKWrapper.Instance
    local fSuccess = function(data)
        local tool = g_ModuleMgr:GetModule(ModuleName.TOOLLIB_MODULE)
        tool:SendShareRecord(2)
    end
    if configModule:IsIgnoreShareCb() then
        fSuccess()
    else
        u8sdk.OnShareSuccess = fSuccess
    end
end

-------------------------------------------
--玩家点击返回按钮
-------------------------------------------
function GameOverResultView:onCloseButtonClick()
    -- local flag, msg = coroutine.resume(self.waitCo)
    -- if not flag then
    --     logError(msg)
    -- 	return
    -- end
    self.room.gameOverResultView = nil
    self.unityViewNode:Destroy()

    self.room:completedWait()
end

function GameOverResultView:destroy()
    self.unityViewNode:Destroy()
end

return GameOverResultView
