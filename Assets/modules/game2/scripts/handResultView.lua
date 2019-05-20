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
local proto = require "scripts/proto/proto"

local greatWinType = proto.dfmahjong.GreatWinType
local miniWinType = proto.dfmahjong.MiniWinType

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
        local viewObj = _ENV.thisMod:CreateUIObject("dafeng", "hand_result")
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
    local en
    if self.msgHandOver.endType ~= proto.mahjong.HandOverType.enumHandOverType_None then
        if self.room.myPlayer.score.score >= 0 then
            en = "Effects_jiemian_ying"
        else
            en = "Effects_jiemian_shu"
        end
    else
        en = "Effects_jiemian_huangzhuang"
    end
    self.ani = animation.play("animations/" .. en .. ".prefab", self.unityViewNode, self.aniPos.x, self.aniPos.y, true)

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
    --庄家
    if self.room.bankerChairID == player.chairID then
        c.zhuang.visible = true
    end
    --头像
end

-------------------------------------------
--更新牌数据
-------------------------------------------
function HandResultView:updatePlayerTileData(player, c)
    local meldDatas = player.melds --落地牌组
    local tilesHand = player.tilesHand --玩家手上的牌（暗牌）排好序的
    local lastTile = player.lastTile --玩家最后一张牌

    --吃碰杠牌
    local rm = "mahjong_mine_meld_"
    for i = 1, 4 do
        local mm = c.melds:GetChild("myMeld" .. i)
        if mm then
            c.melds:RemoveChild(mm, true)
        end
    end
    --摆放牌
    for i, meldData in ipairs(meldDatas) do
        local mv = c.melds:GetChild("meld" .. i)
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
        c.melds:AddChild(meldView)
        player.playerView:mountMeldImage(meldView, meldData)
    end
    --手牌
    local n = 0
    local last = false
    local meldCount = #meldDatas
    local tileCountInHand = #tilesHand
    local isHu = (3 * meldCount + tileCountInHand) > 13
    for i = 1, 14 do
        local oCardObj = c.cards[i]
        oCardObj.visible = false
    end
    for i = 1, tileCountInHand do
        local tiles = tilesHand[i]
        --因为玩家有可能有两张一样的牌，所以要加一个变量来判断是否已处理
        if lastTile == tiles and not last and isHu then --c.card_hu.activeSelf then
            last = true
            tileMounter:mountTileImage(c.cards[14], tiles)
            c.cards[14].visible = true
            c.hu.visible = true
        else
            n = n + 1
            local oCardObj = c.cards[n]
            tileMounter:mountTileImage(oCardObj, tiles)
            oCardObj.visible = true
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
        -- local isMe = player == self.room.myPlayer
        --玩家基本信息
        self:updatePlayerInfoData(player, c)
        local myScore = 0
        --endType == enumHandOverType_None 表示流局 也就是没有人胡牌
        if self.msgHandOver.endType ~= proto.mahjong.HandOverType.enumHandOverType_None then
            local playerScores = player.score --这是在 handleMsgHandOver里面保存进去的
            myScore = playerScores.score

            --分数详情
            self:updatePlayerScoreData(player, c)
        end
        --包牌
        -- if playerScores.winType == pokerfacerf.enumHandOverType_Chucker then
        -- c.textChucker.visible = true
        -- end
        --end
        --牌
        self:updatePlayerTileData(player, c)

        --分数
        if myScore > 0 then
            -- c.textName.transform.visible = false
            -- self:showWin(c)
            c.textCountT.text = "+" .. tostring(myScore)
            c.textCountT.visible = true
            c.textCountLoseT.visible = false
        else
            c.textCountLoseT.text = tostring(myScore)
            c.textCountLoseT.visible = true
            c.textCountT.visible = false
        end
        number = number + 1
    end
end

-------------------------------------------
--更新详细数据   8def07dc-a53f-4851-a88d-9d45d7db126a
-------------------------------------------
function HandResultView:updatePlayerScoreData(player, c)
    local hot = proto.mahjong.HandOverType
    local playerScores = player.score --这是在 handleMsgHandOver里面保存进去的
    local textScore = ""
    if playerScores.specialScore ~= nil and playerScores.specialScore > 0 then
        textScore = "墩子分 +" .. tostring(playerScores.specialScore) .. "  "
    end
    if playerScores.fakeWinScore ~= nil and playerScores.fakeWinScore ~= 0 then
        textScore = textScore .. "包牌  "
    end

    if playerScores.isContinuousBanker then
        textScore = textScore .. "连庄×" .. tostring(playerScores.continuousBankerMultiple / 10) .. "  "
    end

    if playerScores.winType ~= hot.enumHandOverType_None and playerScores.winType ~= hot.enumHandOverType_Chucker then
        local greatWin = playerScores.greatWin
        if greatWin ~= nil and greatWin.greatWinType ~= greatWinType.enumGreatWinType_None then
            --大胡计分
            if greatWin.trimGreatWinPoints ~= nil and greatWin.trimGreatWinPoints > 0 then
                textScore = textScore .. "辣子数 +" .. tostring(greatWin.trimGreatWinPoints / 10) .. "  "
            end
            if greatWin.baseWinScore ~= nil and greatWin.baseWinScore > 0 then
                textScore = textScore .. "基本分" .. tostring(greatWin.baseWinScore) .. "  "
            end
            textScore = textScore .. self:processGreatWin(greatWin)
        else
            --既然不是大胡，必然是小胡  小胡计分
            local miniWin = playerScores.miniWin
            local tt = ""
            if miniWin.miniWinType ~= miniWinType.enumMiniWinType_None then
                tt = self:processMiniWin(miniWin)
                if miniWin.miniMultiple ~= nil and miniWin.miniMultiple > 0 then
                    textScore = textScore .. "倍数" .. tostring(miniWin.miniMultiple / 10) .. "  "
                end
            end
            if tt == "" then
                textScore = textScore .. "小胡  "
            else
                textScore = textScore .. tt
            end
        end
        --这里需要作判断，只有roomType为 大丰的时候  才能显示家家庄
        if self.room.markup and self.room.markup > 0 then
            textScore = textScore .. "家家庄x2  "
        end
    end

    if playerScores.fakeList ~= nil and #playerScores.fakeList > 0 then
        textScore = textScore .. "报听  "
    end
    -- if playerScores.winType == mjproto.enumHandOverType_Chucker then
    --     textScore = textScore.."放炮  "
    -- end
    c.textPlayerScore.text = textScore
end

-------------------------------------------
--处理大胡数据
-------------------------------------------
function HandResultView:processGreatWin(greatWin)
    local textScore = ""
    local gt = greatWin.greatWinType
    if gt == nil then
        return textScore
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_ChowPongKong) then
        textScore = textScore .. "独钓  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_FinalDraw) then
        textScore = textScore .. "海底捞月  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_PongKong) then
        textScore = textScore .. "碰碰胡  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_PureSame) then
        textScore = textScore .. "清一色  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_MixedSame) then
        textScore = textScore .. "混一色  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_ClearFront) then
        textScore = textScore .. "大门清  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_SevenPair) then
        textScore = textScore .. "七对  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_GreatSevenPair) then
        textScore = textScore .. "豪华大七对  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_Heaven) then
        textScore = textScore .. "天胡  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_AfterConcealedKong) then
        textScore = textScore .. "暗杠胡  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_AfterExposedKong) then
        textScore = textScore .. "明杠胡  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_Richi) then
        textScore = textScore .. "起手报听胡牌  "
    end

    --新增5个大胡情况
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_PureSameWithFlowerNoMeld) ~= 0 then
        --清一色，带花但是没有落地
        textScore = textScore .. "清一色  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_PureSameWithMeld) ~= 0 then
        --清一色，有落地
        textScore = textScore .. "清一色  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_MixSameWithFlowerNoMeld) ~= 0 then
        --混一色，带花但是没有落地
        textScore = textScore .. "混一色  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_MixSameWithMeld) ~= 0 then
        --混一色，有落地
        textScore = textScore .. "混一色  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_PongKongWithFlowerNoMeld) ~= 0 then
        --碰碰胡，有花没有落地
        textScore = textScore .. "碰碰胡  "
    end
    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_RobKong) ~= 0 then
        --碰碰胡，有花没有落地
        textScore = textScore .. "明杠冲  "
    end

    if proto.actionsHasAction(gt, greatWinType.enumGreatWinType_OpponentsRichi) ~= 0 then
        textScore = textScore .. "报听  "
    end

    return textScore
end

-------------------------------------------
--处理小胡数据
-------------------------------------------
function HandResultView:processMiniWin(miniWin)
    local textScore = ""
    local mt = miniWin.miniWinType
    --logError(player.userID.." ,小胡 : "..miniWinType)
    if mt == nil then
        return textScore
    end

    if proto.actionsHasAction(mt, miniWinType.enumMiniWinType_Continuous_Banker) then
        textScore = textScore .. "连庄  "
    end
    -- if proto.actionsHasAction(mt, miniWinType.enumMiniWinType_SelfDraw) then
    --textScore = textScore.."自摸  "
    -- end
    if proto.actionsHasAction(mt, miniWinType.enumMiniWinType_NoFlowers) then
        textScore = textScore .. "无花10花  "
    end
    if proto.actionsHasAction(mt, miniWinType.enumMiniWinType_Kong2Discard) then
        textScore = textScore .. "杠冲  "
    end
    if proto.actionsHasAction(mt, miniWinType.enumMiniWinType_Kong2SelfDraw) then
        textScore = textScore .. "杠开  "
    end
    if proto.actionsHasAction(mt, miniWinType.enumMiniWinType_SecondFrontClear) then
        textScore = textScore .. "小门清  "
    end
    return textScore
end

function HandResultView:initHands(view)
    -- 手牌列表
    local hands = {}
    local myHandTilesNode = view:GetChild("hands")
    for i = 1, 14 do
        local cname = "n" .. i
        local card = myHandTilesNode:GetChild(cname)
        card.visible = false
        hands[i] = card
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
    for var = 1, 4 do
        local contentGroupData = {}
        local group = self.unityViewNode:GetChild("player" .. var)
        contentGroupData.group = group
        --头像
        contentGroupData.imageIcon = group:GetChild("head")
        -- contentGroupData.headView = group:SubGet("ImageIcon/Image", "Image")
        --房主标志
        contentGroupData.imageRoom = group:GetChild("roomOwner")
        contentGroupData.imageRoom.visible = false
        --手牌
        contentGroupData.cards = self:initHands(group)
        --牌组
        contentGroupData.melds = group:GetChild("melds")
        --名字
        contentGroupData.textName = group:GetChild("name")
        contentGroupData.textId = group:GetChild("id")
        --庄家
        contentGroupData.zhuang = group:GetChild("zhuang")
        contentGroupData.zhuang.visible = false
        contentGroupData.lianzhuang = group:GetChild("lianzhuang")
        contentGroupData.lianzhuang.visible = false
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
        contentGroupData.textPlayerScore = group:GetChild("score")
        --胡
        contentGroupData.hu = group:GetChild("hu")
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
    if self.ani then
        self.ani.setVisible(false)
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
