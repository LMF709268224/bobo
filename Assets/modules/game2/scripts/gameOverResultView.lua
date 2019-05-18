--[[
    显示一手牌结束后的得分结果
]]
-- luacheck: no self
local GameOverResultView = {}

local fairy = require "lobby/lcore/fairygui"
local animation = require "lobby/lcore/animations"
local logger = require "lobby/lcore/logger"

function GameOverResultView.new(room)
    -- 提高消息队列的优先级为1
    room.host.mq:blockNormal()

    local viewObj = _ENV.thisMod:CreateUIObject("dafeng", "game_over")
    GameOverResultView.unityViewNode = viewObj

    local win = fairy.Window()
    win.contentPane = GameOverResultView.unityViewNode
    GameOverResultView.win = win

    --初始化View
    GameOverResultView:initAllView()
    GameOverResultView.room = room
    --结算数据
    GameOverResultView.msgGameOver = room.msgGameOver

    local backHallBtn = GameOverResultView.unityViewNode:GetChild("backHallBtn")
    backHallBtn.onClick:Set(
        function()
            GameOverResultView:onCloseButtonClick()
        end
    )
    local shanreBtn = GameOverResultView.unityViewNode:GetChild("shanreBtn")
    shanreBtn.onClick:Set(
        function()
            -- GameOverResultView:onShareButtonClick()
        end
    )

    -- if configModule:IsIosAudit() then
    --     shanreBtn.visible = false
    -- end

    --更新数据
    GameOverResultView:updateAllData()

    GameOverResultView.win:Show()
end

-------------------------------------------
--更新房间相关数据
-------------------------------------------
function GameOverResultView:updateRoomData()
    --牌局结算文字动效
    local x = self.aniPos.x
    local y = self.aniPos.y
    animation.play("animations/Effects_jiemian_paijvzongjiesuan.prefab", self.unityViewNode, x, y, true)

    --日期时间
    local date = os.date("%Y-%m-%d %H:%M:%S")
    self.textTime.text = date
    --房间信息
    -- local rule = ""
    local roomNumber = self.room.roomNumber
    --self.textRule.text = self.room:getRule()
    self.textRoomNumber.text = "房号:" .. tostring(roomNumber)
end

-------------------------------------------
--更新玩家基本信息
-------------------------------------------
function GameOverResultView:updatePlayerInfoData(player, c)
    --名字  id
    -- local isMe = player == self.room.myPlayer
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
    if player:isMe() then
        c.imageRoom.visible = true
    end
    --庄家
    if self.room.bankerChairID == player.chairID then
        c.zhuang.visible = true
    end
    --头像
    -- if player.sex == 1 then
    --     c.imageIcon.sprite = dfCompatibleAPI:loadDynPic("playerIcon/boy_img")
    -- else
    --     c.imageIcon.sprite = dfCompatibleAPI:loadDynPic("playerIcon/girl_img")
    -- end
    -- if player.headIconURI ~= nil and player.headIconURI ~= "" then
    -- player.playerView:getPartnerWeixinIcon(
    --     player.headIconURI,
    --     function(texture)
    --         c.imageIcon.transform:SetImage(texture)
    --     end
    -- )
    -- local tool = g_ModuleMgr:GetModule(ModuleName.TOOLLIB_MODULE)
    -- tool:SetUrlImage(c.imageIcon.transform, player.headIconURI)
    -- else
    --     logger.debug("player.headIconURI is nill")
    -- end

    -- if player.avatarID ~= nil and player.avatarID ~= 0 then
    --     local imagePath = string.format("Component/CommonComponent/Bundle/image/box/bk_%d.png", player.avatarID)
    --     c.headView.transform:SetImage(imagePath)
    --     c.headView.transform:GetComponent("Image"):SetNativeSize()
    --     c.headView.transform.localScale = Vector3(0.6, 0.6, 1)
    -- end
end

--设置大赢家相关View
function GameOverResultView:setDYJView(c)
    --local colorSText = "#f8dd26"
    --大赢家动效
    if c ~= nil then
        animation.play("animations/Effects_jiemian_dayingjia.prefab", c.group, c.aniPos.x, c.aniPos.y, true)
    end
end

-------------------------------------------
--更新玩家分数信息
-------------------------------------------
function GameOverResultView:updatePlayerScoreData(playerStat, c)
    local score = playerStat.score
    local chucker = playerStat.chuckerCounter
    -- local winSelfDrawnCounter = playerStat.winSelfDrawnCounter --赢牌局数
    -- c.textWin.text = "胜利局数: " .. winSelfDrawnCounter .. "局"
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
    if score < self.maxChucker then
        self.maxChuckerIndexs = {}
        self.maxChuckerIndexs[1] = c
        self.maxChucker = score
    elseif score == self.maxChucker then
        local n = #self.maxChuckerIndexs
        self.maxChuckerIndexs[n + 1] = c
    end

    if score >= 0 then
        local add = "+"
        if score == 0 then
            add = ""
        end
        c.textCountT.text = add .. tostring(score)
        c.textCountT.visible = true
        c.textCountLoseT.visible = false
    else
        c.textCountLoseT.text = tostring(score)
        c.textCountLoseT.visible = true
        c.textCountT.visible = false
    end
    --胡牌次数
    -- c.textWin.text = tostring(playerStat.winSelfDrawnCounter + playerStat.winChuckCounter)
    --接炮次数
    c.textJiepao.text = "接炮次数: " .. tostring(playerStat.winChuckCounter)
    --放炮次数
    c.textFangpao.text = "放炮次数: " .. tostring(chucker)
    --自摸次数
    c.textZimo.text = "自摸次数: " .. tostring(playerStat.winSelfDrawnCounter)
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
    --暂时保存上一个最佳炮手数据
    self.maxChucker = 0
    self.maxChuckerIndexs = {}

    if self.msgGameOver ~= nil then
        local playerStats = self.msgGameOver.playerStats
        table.sort(
            playerStats,
            function(x, y)
                local a = room:getPlayerByChairID(x.chairID).playerView.viewChairID
                local b = room:getPlayerByChairID(y.chairID).playerView.viewChairID
                return a < b
            end
        )

        if playerStats ~= nil then
            for _, playerStat in ipairs(playerStats) do
                if playerStat ~= nil then
                    local c = self.contentGroup[number]
                    c.group.visible = true
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
            --self.maxScoreIndex.imageWin.visible = true
            end
        -- if self.maxChuckerIndexs ~= nil then
        --     for _, maxChuckerIndex in ipairs(self.maxChuckerIndexs) do
        --         if maxChuckerIndex then
        -- maxChuckerIndex.imagePao:SetActive(true)
        -- end
        --     end
        -- --self.maxScoreIndex.imageWin:SetActive(true)
        -- end
        end
    end
end

-------------------------------------------
--初始化界面
-------------------------------------------
function GameOverResultView:initAllView()
    --日期时间
    self.textTime = self.unityViewNode:GetChild("date")
    --房间信息
    self.textRoomNumber = self.unityViewNode:GetChild("roomNumber")
    --特效位置节点
    self.aniPos = self.unityViewNode:GetChild("aniPos")
    --局数
    -- self.handAmount = self.unityViewNode.transform:Find("HandAmount")
    --付费方式
    -- self.payType = self.unityViewNode.transform:Find("PayType")

    local contentGroup = {}
    for var = 1, 4 do
        local contentGroupData = {}
        local group = self.unityViewNode:GetChild("player" .. var)
        contentGroupData.group = group
        --头像
        contentGroupData.imageIcon = group:GetChild("head")
        --头像框
        -- contentGroupData.headView = group:SubGet("ImageIcon/Image", "Image")
        --房主标志
        contentGroupData.imageRoom = group:GetChild("roomOwner")
        contentGroupData.imageRoom.visible = false
        --大赢家动画位置
        contentGroupData.aniPos = group:GetChild("aniPos")
        -- contentGroupData.imageWin.visible = false
        contentGroupData.zhuang = group:GetChild("zhuang")
        contentGroupData.zhuang.visible = false
        --名字
        contentGroupData.textName = group:GetChild("name")
        contentGroupData.textUserID = group:GetChild("id")
        --赢牌次数
        contentGroupData.textJiepao = group:GetChild("num_jiepao")
        contentGroupData.textFangpao = group:GetChild("num_fangpao")
        contentGroupData.textZimo = group:GetChild("num_zimo")

        --分数（赢）
        contentGroupData.textCountT = group:GetChild("text_win")
        contentGroupData.textCountT.text = "0"
        contentGroupData.textCountT.visible = false
        --分数（输）
        contentGroupData.textCountLoseT = group:GetChild("text_lose")
        contentGroupData.textCountLoseT.text = "0"
        contentGroupData.textCountLoseT.visible = false
        --总得分
        contentGroup[var] = contentGroupData

        group.visible = false
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
    -- local shareMudule = g_ModuleMgr:GetModule(ModuleName.SHARE_MODULE)
    -- shareMudule:ShareGameResult(1, "", 32, 1)
    -- local u8sdk = U8SDK.SDKWrapper.Instance
    -- local fSuccess = function(data)
    --     local tool = g_ModuleMgr:GetModule(ModuleName.TOOLLIB_MODULE)
    --     tool:SendShareRecord(2)
    -- end
    -- if configModule:IsIgnoreShareCb() then
    --     fSuccess()
    -- else
    --     u8sdk.OnShareSuccess = fSuccess
    -- end
end

-------------------------------------------
--玩家点击返回按钮
-------------------------------------------
function GameOverResultView:onCloseButtonClick()
    logger.debug("GameOverResultView:onCloseButtonClick, quit game")
    -- 降低消息队列的优先级为0
    self.room.host.mq:unblockNormal()
    self.win:Hide()
    self.win:Dispose()
    self.unityViewNode = nil
    self.win = nil

    self.room.host.mq:pushQuit()
end

return GameOverResultView
