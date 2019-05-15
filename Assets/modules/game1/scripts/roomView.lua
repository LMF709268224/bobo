--[[
    房间的view，大致上这样划分：凡是属于用户相关的，就放到PlayerView，其余的放到RoomView中
]]
--luacheck:no self
local RoomView = {}

local fairy = require "lobby/lcore/fairygui"
local PlayerView = require("scripts/playerView")
local logger = require "lobby/lcore/logger"
local proto = require "scripts/proto/proto"
local dialog = require "lobby/lcore/dialog"
local chatView = require "lobby/scripts/chat/chatView"
local prompt = require "lobby/lcore/prompt"

local mt = {__index = RoomView}
-- local dfPath = "GuanZhang/Script/"
-- local tileMounter = require(dfPath .. "dfMahjong/tileImageMounter")
-- local dfConfig = require(dfPath .. "dfMahjong/dfConfig")
-- local tool = g_ModuleMgr:GetModule(ModuleName.TOOLLIB_MODULE)
-- local userDataModule = g_ModuleMgr:GetModule(ModuleName.DATASTORAGE_MODULE)
-- local viewModule = g_ModuleMgr:GetModule(ModuleName.VIEW_MODULE)
-- local dispatcher = g_ModuleMgr:GetModule(ModuleName.DISPATCH_MODULE)
-- local configModule = g_ModuleMgr:GetModule("ConfigModule")
-- local dfCompatibleAPI = require(dfPath .. "dfMahjong/dfCompatibleAPI")

function RoomView.new(room)
    local roomView = {}
    setmetatable(roomView, mt)

    _ENV.thisMod:AddUIPackage("lobby/fui_lobby_poker/lobby_poker")
    _ENV.thisMod:AddUIPackage("bg/runfast_bg_2d")
    _ENV.thisMod:AddUIPackage("fgui/runfast")
    _ENV.thisMod:AddUIPackage("setting/runfast_setting")
    local view = _ENV.thisMod:CreateUIObject("runfast", "desk")
    fairy.GRoot.inst:AddChild(view)

    roomView.room = room
    roomView.unityViewNode = view

    -- 根据prefab中的位置，正中下方是Cards/P1，左手是Cards/P4，右手是Cards/P2，正中上方是Cards/P3
    local playerViews = {}
    for i = 1, 3 do
        local playerView = PlayerView.new(view, i)
        playerView:hideAll()
        playerViews[i] = playerView
    end

    roomView.playerViews = playerViews

    roomView.leftPlayerView = playerViews[3]
    roomView.rightPlayerView = playerViews[2]
    roomView.downPlayerView = playerViews[1]

    local voiceBtn = view:GetChild("voice")
    voiceBtn.visible = false
    local chatBtn = view:GetChild("chat")
    chatBtn.onClick:Set(
        function()
            chatView.showChatView()
        end
    )

    local settingBtn = view:GetChild("setting")

    local infoBtn = view:GetChild("info")
    infoBtn.visible = true

    roomView.readyButton = view:GetChild("ready")
    roomView.readyButton.onClick:Set(
        function()
            roomView.room:onReadyButtonClick()
        end
    )

    settingBtn.onClick:Set(
        function()
            roomView:onDissolveClick()
        end
    )
    -- --房间号
    roomView:initRoomNumber()

    --房间状态事件初始化
    roomView:initRoomStatus()

    return roomView
end

function RoomView:pauseResumeButtons(pauseBtnVisible, resumeBtnVisible)
    self.pauseBtn:SetActive(pauseBtnVisible)
    self.resumeBtn:SetActive(resumeBtnVisible)
end

function RoomView:destroyReplayView()
    self.replayUnityViewNode:Destroy()
end

function RoomView:show2ReadyButton()
    self.readyButton.visible = true
end

function RoomView:hide2ReadyButton()
    self.readyButton.visible = false
end

--------------------------------------
--响应玩家点击左上角的退出按钮以及后退事件
--------------------------------------
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

function RoomView:closeRuleView()
    if self.RoomRuleMsgBox then
        self.RoomRuleMsgBox:Close()
    end
end

----------------------------------------------
-- 播放发牌动画
----------------------------------------------
function RoomView:dealAnimation(me, player1, player2)
    local waitCo = coroutine.running()

    -- dfCompatibleAPI:soundPlay("effect/effect_fapai")

    --self.FaPaiAniObj:Show()
    me.playerView:deal()
    player1.playerView:dealOther()
    player2.playerView:dealOther()

    self.unityViewNode:DelayRun(
        2,
        function()
            -- self.FaPaiAniObj:Hide()
            local flag, msg = coroutine.resume(waitCo)
            if not flag then
                msg = debug.traceback(waitCo, msg)
                --error(msg)
                logger.error(msg)
                return
            end
        end
    )

    coroutine.yield()
end

--------------------------------------
--设置当前房间所等待的操作玩家
--------------------------------------
function RoomView:setWaitingPlayer(player)
    --TODO:假设客户端只允许一个等待标志
    --因此设置一个等待时，先把其他的清理掉
    --self.room:startDiscardCountdown(31)
    self:clearWaitingPlayer()
    -- local viewChairID = player.playerView.viewChairID

    player.playerView:setHeadEffectBox(true)
end
--------------------------------------
--清除当前房间的等待玩家标志
--------------------------------------
function RoomView:clearWaitingPlayer()
    for _, v in pairs(self.playerViews) do
        v:setHeadEffectBox(false)
    end
end

--------------------------------------
--初始化房间号
--------------------------------------
function RoomView:initRoomNumber()
    self.roomInfoText = self.unityViewNode:GetChild("top_room_info")
end

--------------------------------------
--显示房间号
--------------------------------------
function RoomView:showRoomNumber()
    local room = self.room
    local num = string.format(tostring(self.room.handStartted) or "0", "/", tostring((self.room.handNum)))
    local str = "房号:" .. room.roomInfo.roomNumber .. " 局数:" .. num
    self.roomInfoText.text = str
    -- if self.room.handStartted and self.room.handStartted > 0 then
    --     self.returnHallBtn:Hide()
    -- end
end

--------------------------------------
--解散房间按钮点击事件
--------------------------------------
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

--------------------------------------
--解散房间按钮点击事件
--------------------------------------
function RoomView:onRetunHallClick()
    local room = self.room
    --先向服务器发送返回大厅请求
    room:onRetunHallClicked()
end

----------------------------------------------------------
-- 获取网络延时，用来刷新wifi信号强度
----------------------------------------------------------
function RoomView:getNetDelay()
    local room = self.room
    local netDelay = 0
    if room:isReplayMode() then
        return netDelay
    end
    local dfsingleton = room.host
    if dfsingleton then
        local ws = dfsingleton.ws
        if ws then
            netDelay = ws:getNetDelay()
        end
    end
    return netDelay
end

----------------------------------------------------------
--注销界面
----------------------------------------------------------
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

----------------------------------------------------------
--初始化房间状态事件
----------------------------------------------------------
function RoomView:initRoomStatus()
    -- 房间正在等待玩家准备
    local onWait = function()
        -- roomView.wind:SetActive(false)
        --等待状态重置上手牌遗留
        self.room:resetForNewHand()
    end

    --房间空闲，客户端永远看不到这个状态
    local onIdle = function()
    end

    -- 游戏开始了
    local onPlay = function()
        self:showRoomNumber()
    end

    --房间已经被删除，客户端永远看不到这个状态
    local onDelete = function()
    end

    local status = {}

    status[proto.pokerface.RoomState.SRoomIdle] = onIdle
    status[proto.pokerface.RoomState.SRoomWaiting] = onWait
    status[proto.pokerface.RoomState.SRoomPlaying] = onPlay
    status[proto.pokerface.RoomState.SRoomDeleted] = onDelete
    self.statusHandlers = status
end

function RoomView:hideNoFriendTips()
    for _, tip in ipairs(self.noFriendTips) do
        tip:Hide()
    end
end

----------------------------------------------------------
--根据游戏状态控制两个按钮的可见性
----------------------------------------------------------
function RoomView:updateLeaveAndDisbandButtons()
    local room = self.room

    local handStartted = room.handStartted
    if handStartted > 0 then
        self.exitBtn:SetActive(false)
        self.dissolveBtn:SetActive(true)
        return
    end
    self.exitBtn:SetActive(true)
    self.dissolveBtn:SetActive(false)
    -- if room.ownerID == room:me().userID then
    --     self.exitBtn:SetActive(true)
    --     self.dissolveBtn:SetActive(false)
    -- else
    --     self.exitBtn:SetActive(true)
    --     self.dissolveBtn:SetActive(false)
    -- end
end

----------------------------------------------------------
--根据房间的状态做一些开关变量切换
----------------------------------------------------------
function RoomView:onUpdateStatus(state)
    local handler = self.statusHandlers[state]
    if handler ~= nil then
        handler(self)
    end
end

----------------------------------------------------------
--初始化回退键动作
----------------------------------------------------------
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
            if room.ownerID ~= room:me().userID and self.exitBtn.activeSelf then
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
