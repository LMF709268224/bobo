--[[
    显示一手牌结束后的得分结果
]]
--luacheck: no self
local HandResultView = {}

-- local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"
local fairy = require "lobby/lcore/fairygui"
local animation = require "lobby/lcore/animations"
local tileMounter = require("scripts/tileImageMounter")

function HandResultView.new(room)
    -- 提高消息队列的优先级为1
    if not room:isReplayMode() then
        room.host.mq:blockNormal()
    end

    -- local handResultView = {}
    -- setmetatable(handResultView, mt)
    if HandResultView.unityViewNode then
        logger.debug("HandResultView ---------------------")
    else
        local viewObj = _ENV.thisMod:CreateUIObject("runfast", "hand_result")
        HandResultView.unityViewNode = viewObj

        local win = fairy.Window()
        win.contentPane = HandResultView.unityViewNode
        HandResultView.win = win

        --初始化View
        HandResultView:initAllView()

        -- 由于win隐藏，而不是销毁，隐藏后和GRoot脱离了关系，因此需要
        -- 特殊销毁
        _ENV.thisMod:RegisterCleanup(
            function()
                win:Dispose()
            end
        )
    end

    HandResultView.room = room
    --结算数据
    HandResultView.msgHandOver = room.msgHandOver

    -- fairy.GRoot.inst:AddChild(viewObj)

    -- local screenWidth = CS.UnityEngine.Screen.width
    -- local screenHeight = CS.UnityEngine.Screen.height
    -- win:SetXY(screenWidth / 2, screenHeight / 2)

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
    HandResultView.players = players

    local againBtn = HandResultView.unityViewNode:GetChild("againBtn")
    againBtn.onClick:Set(
        function()
            HandResultView:onAgainButtonClick()
        end
    )
    local shanreBtn = HandResultView.unityViewNode:GetChild("shanreBtn")
    shanreBtn.onClick:Set(
        function()
            -- handResultView:onShareButtonClick()
        end
    )

    if room:isReplayMode() then
        againBtn.visible = false
        shanreBtn.visible = false
    end

    --更新数据
    HandResultView:updateAllData()

    HandResultView.win:Show()
    -- return handResultView
end

-------------------------------------------
--更新房间相关数据
-------------------------------------------
function HandResultView:updateRoomData()
    --背景（输还是赢）
    --endType == enumHandOverType_None 表示流局 也就是没有人胡牌
    --if self.msgHandOver.endType ~= pokerfacerf.enumHandOverType_None then
    local effectName = "Effects_JieMian_ShiBai"
    if self.room:me().score.score > 0 then
        effectName = "Effects_JieMian_ShengLi"
    end
    animation.play("animations/" .. effectName .. ".prefab", self.unityViewNode, self.aniPos.x, self.aniPos.y, true)

    --日期时间
    local date
    if not self.room:isReplayMode() then
        date = os.date("%Y-%m-%d %H:%M")
    else
        local startTime = self.room.replay.msgHandRecord.endTime
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

    -- local handNum = self.room.handNum
    -- local handStartted = self.room.handStartted
    -- local handNum = self.room.handNum
    -- if handNum ~= nil and handStartted ~= nil then
    --     self.handAmount.text = "局数: " .. tostring(handStartted) .. "/" .. tostring(handNum)
    -- end
    -- local roomConfig = self.room.roomInfo.config
    -- if roomConfig ~= nil and roomConfig ~= "" then
    --     logger.debug("roomConfig : ", roomConfig)
    --     local config = Json.decode(roomConfig)
    --     if config.payType ~= nil then
    --         self.payType.text = "付费:房主支付"
    --         if config.payType == 1 then
    --             self.payType.text = "付费:钻石平摊"
    --         end
    --     end
    -- end
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
    c.textId.text = "ID:" .. userID
    --房主
    if player:isMe() then
        c.imageRoom.visible = true
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
    -- local imagePath = string.format("Component/CommonComponent/Bundle/image/box/bk_%d.png", player.avatarID)
    -- c.headBox.transform:SetImage(imagePath)
    -- c.headBox.transform:GetComponent("Image"):SetNativeSize()
    -- c.headBox.transform.localScale = Vector3(0.8, 0.8, 1)
    -- end
end

-------------------------------------------
--更新牌数据
-------------------------------------------
function HandResultView:updatePlayerTileData(player, c)
    local cardsOnHand = player.cardsOnHand --玩家手上的牌（暗牌）排好序的

    --手牌
    local cardCountOnHand = #cardsOnHand
    if cardCountOnHand > 0 then
        for i = 1, cardCountOnHand do
            local tiles = cardsOnHand[i]
            local oCardObj = c.cards[i]
            tileMounter:mountTileImage(oCardObj, tiles)
            oCardObj.visible = true
        end
        c.textPlayerScore.text = "剩余手牌:" .. tostring(cardCountOnHand)
        c.textPlayerScore.visible = true
    else
        c.textPlayerScore.visible = false
        for i = 1, 16 do
            local oCardObj = c.cards[i]
            oCardObj.visible = false
        end
    end
end
-------------------------------------------
--更新显示数据
-------------------------------------------
function HandResultView:updateAllData()
    local number = 1

    --整个房间数据
    self:updateRoomData()

    for _, player in ipairs(self.players) do
        local c = self.contentGroup[number]
        c.group.visible = true
        -- local isMe = player == self.room:me()
        --玩家基本信息
        self:updatePlayerInfoData(player, c)
        --endType == enumHandOverType_None 表示流局 也就是没有人胡牌
        --if self.msgHandOver.endType ~= pokerfacerf.enumHandOverType_None then
        local playerScores = player.score --这是在 handleMsgHandOver里面保存进去的
        local myScore = playerScores.score
        --包牌
        -- if playerScores.winType == pokerfacerf.enumHandOverType_Chucker then
        -- c.textChucker:SetActive(true)
        -- end
        --end
        --牌
        self:updatePlayerTileData(player, c)

        --分数
        if myScore > 0 then
            c.textCountT.text = "+" .. tostring(myScore)
            c.textCountT.visible = true
            c.textCountLoseT.visible = false
            -- c.textName.transform:SetActive(false)
            self:showWin(c)
        else
            c.textCountLoseT.text = tostring(myScore)
            c.textCountLoseT.visible = true
            c.textCountT.visible = false
        end
        number = number + 1
    end
end
--显示赢标志
function HandResultView:showWin(c)
    animation.play("animations/Effects_jiemian_huosheng.prefab", c.group, c.aniPos.x, c.aniPos.y, true)
    -- local prefabName = dfConfig.PATH.EFFECTS_GZ .. dfConfig.EFF_DEFINE.SUB_JIEMIAN_WIN .. ".prefab"
    -- local effobj = Animator.PlayLoop(prefabName, self.canvasOrder)
    -- effobj:SetParent(c.group.transform, false)
    -- effobj.localPosition = c.winImagePos.localPosition --Vector3(1.6, 0.8, 0)
end

function HandResultView:initHands(view)
    -- 手牌列表
    local hands = {}
    local myHandTilesNode = view:GetChild("hands")
    for i = 1, 16 do
        local cname = "n" .. i
        local go = myHandTilesNode:GetChild(cname)
        if go ~= nil then
            local card = _ENV.thisMod:CreateUIObject("runfast", "desk_poker_number_lo")
            card.position = go.position
            card.scale = go.scale
            myHandTilesNode:AddChild(card)
            card.visible = false
            hands[i] = card
        end
    end
    return hands
end

-------------------------------------------
--初始化界面
-------------------------------------------
function HandResultView:initAllView()
    --背景
    --日期时间
    self.textTime = self.unityViewNode:GetChild("date")
    --房间信息
    self.textRoomNumber = self.unityViewNode:GetChild("roomNumber")
    --特效位置节点
    self.aniPos = self.unityViewNode:GetChild("aniPos")

    local contentGroup = {}
    for var = 1, 3, 1 do
        local contentGroupData = {}
        local group = self.unityViewNode:GetChild("player" .. var)
        contentGroupData.group = group
        --头像
        contentGroupData.imageIcon = group:GetChild("head")
        -- contentGroupData.headBox = group:SubGet("ImageIcon/Image", "Image")
        --房主标志
        contentGroupData.imageRoom = group:GetChild("roomOwner")
        contentGroupData.imageRoom.visible = false
        --牌详情
        contentGroupData.cards = self:initHands(group)
        --名字
        contentGroupData.textName = group:GetChild("name")
        contentGroupData.textId = group:GetChild("id")
        --分数为正的时候显示
        contentGroupData.textCountT = group:GetChild("text_win")
        contentGroupData.textCountT.text = "0"
        contentGroupData.textCountT.visible = false
        --分数为负的时候显示
        contentGroupData.textCountLoseT = group:GetChild("text_lose")
        contentGroupData.textCountLoseT.text = "0"
        contentGroupData.textCountLoseT.visible = false
        --赢标志的位置
        -- contentGroupData.winImagePos = group:Find("WinImagePos")
        --剩余牌数
        contentGroupData.textPlayerScore = group:GetChild("remainderHands")
        --获胜节点位置
        contentGroupData.aniPos = group:GetChild("aniPos")

        --保存userID
        contentGroupData.userID = ""

        --logError("initAllView var : "..var)
        contentGroup[var] = contentGroupData

        group.visible = false
    end
    self.contentGroup = contentGroup
end

-------------------------------------------
--玩家点击“继续”按钮，注意如果牌局结束，此按钮
--是“大结算”
-------------------------------------------
function HandResultView:onAgainButtonClick()
    -- 降低消息队列的优先级为0
    local room = self.room
    if not room:isReplayMode() then
        room.host.mq:unblockNormal()
    end

    self.win:Hide()
    if self.msgHandOver.continueAble then
        self.room.host:sendPlayerReadyMsg()
    end
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
    -- local shareMudule = g_ModuleMgr:GetModule(ModuleName.SHARE_MODULE)
    -- shareMudule:ShareGameResult(1, "", 32, 1)
    -- local u8sdk = U8SDK.SDKWrapper.Instance
    -- local fSuccess = function(data)
    --     local tool = g_ModuleMgr:GetModule(ModuleName.TOOLLIB_MODULE)
    --     tool:SendShareRecord(2)
    -- end
    -- u8sdk.OnShareSuccess = fSuccess
end

return HandResultView
