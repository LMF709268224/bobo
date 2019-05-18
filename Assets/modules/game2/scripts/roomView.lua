--[[
    房间的view，大致上这样划分：凡是属于用户相关的，就放到PlayerView，其余的放到RoomView中
]]
--luacheck:no self
local RoomView = {}

local fairy = require "lobby/lcore/fairygui"
local PlayerView = require("scripts/playerView")
local logger = require "lobby/lcore/logger"
local proto = require "scripts/proto/proto"
local mjproto = proto.mahjong
local dialog = require "lobby/lcore/dialog"
local chatView = require "lobby/scripts/chat/chatView"
local prompt = require "lobby/lcore/prompt"
local tileMounter = require("scripts/tileImageMounter")
local animation = require "lobby/lcore/animations"
local CS = _ENV.CS

local mt = {__index = RoomView}

function RoomView.new(room)
    local roomView = {}
    setmetatable(roomView, mt)

    _ENV.thisMod:AddUIPackage("lobby/fui_lobby_mahjong/lobby_mahjong")
    _ENV.thisMod:AddUIPackage("fgui/dafeng")
    _ENV.thisMod:AddUIPackage("setting/runfast_setting")
    local view = _ENV.thisMod:CreateUIObject("dafeng", "desk")
    fairy.GRoot.inst:AddChild(view)

    roomView.room = room
    roomView.unityViewNode = view

    -- 根据prefab中的位置，正中下方是Cards/P1，左手是Cards/P4，右手是Cards/P2，正中上方是Cards/P3
    local playerViews = {}
    for i = 1, 4 do
        local playerView = PlayerView.new(view, i)
        playerView:hideAll()
        playerViews[i] = playerView
    end

    roomView.playerViews = playerViews

    roomView.leftPlayerView = playerViews[4]
    roomView.upPlayerView = playerViews[3]
    roomView.rightPlayerView = playerViews[2]
    roomView.downPlayerView = playerViews[1]

    roomView:initButton(view)
    --房间状态事件初始化
    roomView:initRoomStatus()

    roomView:initOtherView()

    roomView:initTingData()
    roomView:initMeldsPanel()

    return roomView
end

--------------------------------------
--初始化
--------------------------------------
function RoomView:initButton(view)
    local chatBtn = view:GetChild("chatBtn")
    chatBtn.onClick:Set(
        function()
            chatView.showChatView()
        end
    )

    local settingBtn = view:GetChild("settingBtn")

    local infoBtn = view:GetChild("guizeBtn")
    infoBtn.visible = true

    self.readyButton = view:GetChild("ready")
    self.readyButton.visible = false
    self.readyButton.onClick:Set(
        function()
            self.room:onReadyButtonClick()
        end
    )

    settingBtn.onClick:Set(
        function()
            self:onDissolveClick()
        end
    )
end

function RoomView:initOtherView()
    -- 房间号
    self.roomInfoText = self.unityViewNode:GetChild("roomInfo")
    -- 风圈和当前操作玩家指示箭头roundMarkArrow
    local roundMarks = {}
    self.roundMarkView = self.unityViewNode:GetChild("roundMask")
    for i = 1, 4 do
        local roundMark = self.roundMarkView:GetChild("n" .. i)
        roundMarks[i] = roundMark
    end
    self.roundMarks = roundMarks
    self.wind = self.unityViewNode:GetChild("n3")
    self.windTile = self.unityViewNode:GetChild("fengquan")
    self.wind.visible = false
    self.windTile.visible = false

    --倒计时
    self.countDownText = self.roundMarkView:GetChild("num")
    --道具
    self.donateMoveObj = self.unityViewNode:GetChild("donate")
    --剩牌
    self.tilesInWall = self.unityViewNode:GetChild("tilesInWall")
end

--初始化房间状态事件
function RoomView:initRoomStatus()
    -- 房间正在等待玩家准备
    local onWait = function()
        self.wind.visible = false
        self.windTile.visible = false
        self.tilesInWall.visible = false

        self.roundMarkView.visible = false
        self:stopDiscardCountdown()
        --等待状态重置上手牌遗留
        self.room:resetForNewHand()
    end

    --房间空闲，客户端永远看不到这个状态
    local onIdle = function()
    end

    -- 游戏开始了
    local onPlay = function()
        -- roomView.invitButton.visible = false
        -- roomView.returnHallBtn.visible = false
        self.tilesInWall.visible = true
        self.wind.visible = false --发牌的时候，或者掉线恢复的时候会设置风圈因此此处不需要visible
        self.windTile.visible = false

        self.roundMarkView.visible = true
        self:clearWaitingPlayer()
        self:showRoomNumber()
    end

    --房间已经被删除，客户端永远看不到这个状态
    local onDelete = function()
    end

    local status = {}

    status[proto.mahjong.RoomState.SRoomIdle] = onIdle
    status[proto.mahjong.RoomState.SRoomWaiting] = onWait
    status[proto.mahjong.RoomState.SRoomPlaying] = onPlay
    status[proto.mahjong.RoomState.SRoomDeleted] = onDelete
    self.statusHandlers = status
end

--初始化显示听牌详情界面
function RoomView:initTingData()
    self.listensObj = self.unityViewNode:GetChild("listensPanel")
    self.listensObjList = self.listensObj:GetChild("list").asList
    self.listensObjNum = self.listensObj:GetChild("num")

    self.listensObjList.itemRenderer = function(index, obj)
        self:renderListensListItem(index, obj)
    end
    self.listensObjList:SetVirtual()

    self.listensObj.onClick:Set(
        function()
            self.listensObj.visible = false
        end
    )
end

function RoomView:renderListensListItem(index, obj)
    local data = self.listensDataList[index + 1]
    local t = obj:GetChild("n1")
    local num = obj:GetChild("num")
    num.text = data.Num .. "张"
    tileMounter:mountTileImage(t, data.Card)
end

--面子牌选择面板
function RoomView:initMeldsPanel()
    -- local meldMap = {}
    self.meldOpsPanel = self.unityViewNode:GetChild("meldOpsPanel")
    self.multiOpsObj = self.meldOpsPanel:GetChild("list").asList
    self.multiOpsObj.itemRenderer = function(index, obj)
        self:renderMultiOpsListItem(index, obj)
    end
    self.multiOpsObj.onClickItem:Add(
        function(onClickItem)
            self:onMeldOpsClick(onClickItem.data.name)
        end
    )
end

function RoomView:renderMultiOpsListItem(index, obj)
    local data = self.multiOpsDataList[index + 1]
    obj.name = index
    local MJ  --用来显示可选择的牌
    if data.meldType == mjproto.MeldType.enumMeldTypeSequence then
        --吃的时候exp是3，所以第4个牌可以隐藏起来
        obj:GetChild("n4").visible = false
        MJ = {data.tile1, data.tile1 + 1, data.tile1 + 2}
    else
        MJ = {data.tile1, data.tile1, data.tile1, data.tile1}
    end
    for j, v in ipairs(MJ) do
        local oCurCard = obj:GetChild("n" .. j)
        tileMounter:mountTileImage(oCurCard, v)
        oCurCard.visible = true
    end

    obj.visible = true
end

function RoomView:onMeldOpsClick(index)
    local data = self.multiOpsDataList[index + 1]
    local actionMsg = {}
    actionMsg.qaIndex = data.actionMsg.qaIndex
    actionMsg.action = data.actionMsg.action
    actionMsg.tile = data.actionMsg.tile
    actionMsg.meldType = data.meldType
    actionMsg.meldTile1 = data.tile1
    if data.meldType == mjproto.MeldType.enumMeldTypeConcealedKong then
        actionMsg.tile = data.tile1
        actionMsg.action = mjproto.ActionType.enumActionType_KONG_Concealed
    elseif data.meldType == mjproto.MeldType.enumMeldTypeTriplet2Kong then
        actionMsg.tile = data.tile1
        actionMsg.action = mjproto.ActionType.enumActionType_KONG_Triplet2
    end

    self.room.myPlayer:sendActionMsg(actionMsg)
    self.room.myPlayer.playerView:hideOperationButtons()
    self.meldOpsPanel.visible = false
end

--------------------------------------
--操作ui
--------------------------------------
function RoomView:show2ReadyButton()
    self.readyButton.visible = true
end

function RoomView:hide2ReadyButton()
    self.readyButton.visible = false
end
--响应玩家点击左上角的退出按钮以及后退事件
function RoomView:onExitButtonClicked()
    local roomView = self

    if roomView.room ~= nil and roomView.room.handStartted > 0 then
        prompt.showPrompt("牌局已经开始，请申请解散房间")
        return
    end

    local room = roomView.room
    local msg = "确实要退出房间吗？"
    dialog:showDialog(
        msg,
        function()
            room.host:triggerLeaveRoom()
        end,
        function()
            --nothing to do
        end
    )
end

-- 播放牌局开始动画
function RoomView:gameStartAnimation()
    local screenWidth = CS.UnityEngine.Screen.width
    local screenHeight = CS.UnityEngine.Screen.height
    local x = screenWidth / 2
    local y = screenHeight / 2
    animation.coplay("animations/Effects_jiemian_duijukaishi.prefab", self.unityViewNode, x, y)
end

function RoomView:startDiscardCountdown()
    --清理定时器
    self.unityViewNode:StopTimer("roomViewCountDown")

    self.leftTime = 0
    --起定时器
    self.unityViewNode:StartTimer(
        "roomViewCountDown",
        1,
        0,
        function()
            self.leftTime = self.leftTime + 1
            self.countDownText.text = self.leftTime
            if self.leftTime >= 999 then
                self.unityViewNode:StopTimer("roomViewCountDown")
            end
        end,
        self.leftTime
    )
end

function RoomView:stopDiscardCountdown()
    --清理定时器
    self.unityViewNode:StopTimer("roomViewCountDown")
    self.countDownText.text = ""
end

--设置当前房间所等待的操作玩家
function RoomView:setWaitingPlayer(player)
    --TODO:假设客户端只允许一个等待标志
    --因此设置一个等待时，先把其他的清理掉
    self:startDiscardCountdown()
    self:clearWaitingPlayer()
    local viewChairID = player.playerView.viewChairID
    self.roundMarks[viewChairID].visible = true

    player.playerView:setHeadEffectBox(true)
end
--清除当前房间的等待玩家标志
function RoomView:clearWaitingPlayer()
    for _, mask in ipairs(self.roundMarks) do
        mask.visible = false
    end
    for _, v in pairs(self.playerViews) do
        v:setHeadEffectBox(false)
    end
end

--显示房间号
function RoomView:showRoomNumber()
    local room = self.room
    local num = string.format(tostring(self.room.handStartted) or "0", "/", tostring((self.room.handNum)))
    local str = "房号:" .. room.roomInfo.roomNumber .. " 局数:" .. num
    self.roomInfoText.text = str
    -- if self.room.handStartted and self.room.handStartted > 0 then
    --     self.returnHallBtn:Hide()
    -- end
end

--解散房间按钮点击事件
function RoomView:onDissolveClick()
    local msg = "确实要申请解散房间吗？"
    local roomView = self

    dialog.showDialog(
        msg,
        function()
            roomView.room:onDissolveClicked()
        end,
        function()
            -- do nothing
        end
    )
end

--注销界面
function RoomView:unInitialize()
    self:unregisterBroadcast()
    if self.chatView ~= nil then
        self.chatView:UnRegisterListener()
        self.chatView = nil
    end

    self.skinManager:Clear()

    -- for k, v in pairs(self.timer) do
    --     if v then
    --         StopTimer(v)
    --     end
    -- end
end

--根据房间的状态做一些开关变量切换
function RoomView:onUpdateStatus(state)
    local handler = self.statusHandlers[state]
    if handler ~= nil then
        handler(self)
    end
end

--显示出牌提示箭头
function RoomView:setArrowByParent(btn)
    local pos = btn:GetChild("pos")
    local x = pos.x
    local y = pos.y
    self.arrowObj = animation.play("animations/Effects_UI_jiantou.prefab", btn, x, y, true)
    self.arrowObj.wrapper.scale = pos.scale
    self.arrowObj.setVisible(true)
end

--------------------------------------
--隐藏出牌提示箭头
--------------------------------------
function RoomView:setArrowHide()
    if self.arrowObj then
        self.arrowObj.setVisible(false)
    end
end

--------------------------------------
--家家庄标志
--------------------------------------
function RoomView:setJiaJiaZhuang()
    -- self.jiaJiaZhuang:SetActive(self.room.markup > 0)
    --self.playerViews[index]:setHeadEffectBox()
end

--------------------------------------
--设置当前房间所使用的风圈
--------------------------------------
function RoomView:setRoundMask(index)
    logger.debug("llwant , set round mask = " .. index)

    -- --设置风圈和被当做花牌的风牌
    self.wind.visible = true
    self.windTile.visible = true
    tileMounter:mountTileImage(self.windTile, self.room.windFlowerID)

    --self.playerViews[index]:setHeadEffectBox()
end

--隐藏听牌详情界面
function RoomView:hideTingDataView()
    self.listensObj.visible = false
end

--显示听牌详情界面
function RoomView:showTingDataView(data)
    if not data or #data == 0 then
        self.listensObj.visible = false
        return
    end
    local len = #data
    self.listensDataList = data

    local width = len <= 2 and 150 or 290
    local height = len > 4 and 230 or 110
    self.listensObjList:SetSize(width, height)
    local nCount = 0
    for _, d in ipairs(data) do
        nCount = nCount + d.Num
    end
    self.listensObjNum.text = nCount .. "张"
    self.listensObjList.numItems = len
    self.listensObj.visible = true
end

--显示面子牌组选择界面
function RoomView:showOrHideMeldsOpsPanel(map)
    local size = #map
    self.multiOpsDataList = map
    self.multiOpsObj.numItems = size
    self.multiOpsObj:ResizeToFit(#map)
    self.meldOpsPanel.visible = size > 0
end

--初始化回退键动作
function RoomView:handleOnbackPress()
    local roomView = self
    local room = roomView.room

    if room:isReplayMode() then
        roomView.replayUnityViewNode.OnMenuBack = function()
            local dfReplay = room.dfReplay
            dfReplay:onExitReplay()
            --self:onExitButtonClicked()
        end
    else
        roomView.unityViewNode.OnMenuBack = function()
            if room.ownerID ~= room.myPlayer.userID and self.exitBtn.activeSelf then
                self:onExitButtonClicked()
            else
                if room.handResultView then
                    logger.debug("on back OnMenuBack ")
                    room.handResultView:onAgainButtonClick()
                    return
                end

                if self.menuPanel.activeSelf then
                    self.menuPanel:Hide()
                    return
                end

                if self.chatView.transform.gameObject.activeSelf then
                    self.chatView:Hide()
                    return
                end

                self:onDissolveClick()
            end
        end
    end
end

return RoomView
