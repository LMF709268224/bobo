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
local tileMounter = require("scripts/tileImageMounter")
local animation = require "lobby/lcore/animations"

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

    -- local voiceBtn = view:GetChild("voice")
    -- voiceBtn.visible = false

    local chatBtn = view:GetChild("chatBtn")
    chatBtn.onClick:Set(
        function()
            chatView.showChatView()
        end
    )

    local settingBtn = view:GetChild("settingBtn")

    local infoBtn = view:GetChild("guizeBtn")
    infoBtn.visible = true

    roomView.readyButton = view:GetChild("ready")
    roomView.readyButton.visible = false
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
    -- 聊天
    -- roomView:iniChatButtons()
    -- -- 语音
    -- roomView:initVoiceButton()
    -- --房间号
    roomView:initRoomNumber()
    -- --手机基本信息
    -- roomView:initPhoneInfo()
    -- --房间温馨提示
    -- roomView:initRoomTip()

    --房间状态事件初始化
    roomView:initRoomStatus()

    roomView:initOtherView()

    roomView:initTingData()

    -- -- 房间规则
    -- roomView:initRoomRule()

    --注册消息通知
    --notificationCenter:register(self, self.OnMessage, Notifications.OnInGameChatMessage)
    --notificationCenter:register(self, OnPlayerChat, "PlayerChat") --收到聊天信息

    -- if room:isReplayMode() then
    --     local extendFunc = unityViewNode.transform:Find("ExtendFuc")
    --     extendFunc.visible = false

    --     --roomView.replayUnityViewNode = ViewManager.Open("LZVideoView")

    --     local videoView =
    --         viewModule:CreatePanel(
    --         {
    --             luaPath = dfPath .. "View/LZVideoView",
    --             resPath = "GameModule/GuanZhang/_AssetsBundleRes/prefab/bund2/LZVideoView.prefab",
    --             parentNode = unityViewNode.transform,
    --             superClass = unityViewNode
    --         }
    --     )
    --     local uiDepth = videoView:GetComponent("UIDepth")
    --     if not uiDepth then
    --         uiDepth = videoView:AddComponent(UIDepth)
    --     end
    --     uiDepth.canvasOrder = unityViewNode.order + 3
    --     roomView.replayUnityViewNode = unityViewNode

    --     local exitBtn = roomView.replayUnityViewNode.transform:Find("LZVideoView/ExitButt")
    --     local ruleBtn = roomView.replayUnityViewNode.transform:Find("LZVideoView/RuleBtn")
    --     local resumeBtn = roomView.replayUnityViewNode.transform:Find("LZVideoView/ButtObjs/PlayButt")
    --     local pauseBtn = roomView.replayUnityViewNode.transform:Find("LZVideoView/ButtObjs/StopButt")
    --     local speedUPBtn = roomView.replayUnityViewNode.transform:Find("LZVideoView/ButtObjs/SpeedUp")
    --     local speedDownBtn = roomView.replayUnityViewNode.transform:Find("LZVideoView/ButtObjs/SpeedDown")
    --     local ButtObjsObj = roomView.replayUnityViewNode.transform:Find("LZVideoView/ButtObjs")

    --     roomView.replayUnityViewNode:AddClick(
    --         "LZVideoView/BackGround/bg00",
    --         function()
    --             ButtObjsObj:SetActive(not ButtObjsObj.activeSelf)
    --         end
    --     )

    --     roomView.resumeBtn = resumeBtn
    --     roomView.pauseBtn = pauseBtn
    --     resumeBtn.visible = false
    --     pauseBtn.visible = false

    --     local dfReplay = room.dfReplay
    --     roomView.replayUnityViewNode:AddClick(
    --         exitBtn,
    --         function()
    --             dfReplay:onExitReplay()
    --         end
    --     )
    --     roomView.replayUnityViewNode:AddClick(
    --         ruleBtn,
    --         function()
    --             -- 回播的时候,放在messagebox 里面
    --             -- roomView:showRuleView()
    --             viewModule:OpenMsgBox(
    --                 {
    --                     luaPath = "GuanZhang.Script.View.RoomRuleMsgBox",
    --                     resPath = "GameModule/GuanZhang/_AssetsBundleRes/prefab/bund2/RoomRuleMsgBox.prefab"
    --                 },
    --                 room:getRoomConfig()
    --             )
    --             -- local rule = require("RuleComponent.Script.RuleModule")
    --             -- local ruleModule = g_ModuleMgr:GetModule(rule.moduleName)
    --             -- if not ruleModule then
    --             --     g_ModuleMgr:AddModule(rule.moduleName, rule)
    --             -- end
    --             -- local dispatcher = g_ModuleMgr:GetModule(ModuleName.DISPATCH_MODULE)
    --             -- dispatcher:dispatch("OPEN_RULE_VIEW")
    --         end
    --     )
    --     roomView.replayUnityViewNode:AddClick(
    --         pauseBtn,
    --         function()
    --             dfReplay:onPause()
    --         end
    --     )
    --     roomView.replayUnityViewNode:AddClick(
    --         resumeBtn,
    --         function()
    --             dfReplay:onPauseResume()
    --         end
    --     )
    --     roomView.replayUnityViewNode:AddClick(
    --         speedUPBtn,
    --         function()
    --             dfReplay:increaseSpeed()
    --         end
    --     )
    --     roomView.replayUnityViewNode:AddClick(
    --         speedDownBtn,
    --         function()
    --             dfReplay:decreaseSpeed()
    --         end
    --     )

    --     -- 战绩播放恢复界面
    --     roomView.replayUnityViewNode.OnResume = function()
    --         --g_commonModule:ShowTip("roomView.replayUnityViewNode.OnResume")
    --         local WeixinInvitedContent = Native.GetWeixinInvitedContent()
    --         if (WeixinInvitedContent and #WeixinInvitedContent > 0) then
    --             local userData = g_dataModule:GetUserData()
    --             local isWeixinInvited = userData:getWeixinInvited()
    --             if isWeixinInvited == false then
    --                 isWeixinInvited = true
    --                 userData:setWeixinInvited(isWeixinInvited)
    --             end
    --             dfReplay:onExitReplay()
    --         end
    --     end
    -- end

    -- roomView:handleOnbackPress()

    -- if NeedHideForIos then
    --     roomView.roomNumberObject.localPosition = Vector3(0, 42, 0)
    -- end

    -- local function ruleViewCountdown()
    --     --打开页面
    --     roomView:showRuleView()
    --     --重置定时器
    --     unityViewNode:CancelDelayRun(self.ruleViewDelay)
    --     self.ruleViewDelay = unityViewNode:DelayRun(2,
    --         function()
    --             roomView:closeRuleView()
    --         end
    --     )
    -- end

    -- if not room:isReplayMode() then
    --     unityViewNode:DelayRun(
    --         0.8,
    --         function(...)
    --             ruleViewCountdown()
    --         end
    --     )
    -- end

    -- logger.debug("进入子游戏关张房间完成，当前系统时间：", os.time())
    return roomView
end

function RoomView:initOtherView()
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
end

function RoomView:pauseResumeButtons(pauseBtnVisible, resumeBtnVisible)
    self.pauseBtn.visible = pauseBtnVisible
    self.resumeBtn.visible = resumeBtnVisible
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

function RoomView:openChatView()
    -- local singleton = require(dfPath .. "dfMahjong/dfSingleton")
    -- local instance = singleton:getSingleton()
    -- local layer =
    --     viewModule:CreatePanel(
    --     {
    --         luaPath = "ChatComponent.Script.ChatView",
    --         resPath = "Component/ChatComponent/Bundle/prefab/ChatPanelInGame.prefab",
    --         superClass = self.unityViewNode,
    --         parentNode = self.unityViewNode.transform
    --     },
    --     instance,
    --     dfConfig.CommonLanguage
    -- )
    -- local uiDepth = layer:GetComponent("UIDepth")
    -- if not uiDepth then
    --     uiDepth = layer:AddComponent(UIDepth)
    -- end
    -- uiDepth.canvasOrder = self.unityViewNode.order + 2
    -- return layer
end

function RoomView:iniChatButtons()
    -- self.chatTextBtn = self.unityViewNode.transform:Find("ExtendFuc/RightBtns/chat_text_btn")
    -- --self.PengBtn.visible = false
    -- -- initChatPanelInGame()
    -- self.chatView = self:openChatView()
    -- self.chatView:Hide()
    -- self.unityViewNode:AddClick(
    --     self.chatTextBtn,
    --     function()
    --         if not self.chatView then
    --             self.chatView = self:openChatView()
    --         else
    --             self.chatView:Show()
    --         end
    --         --ShowInGameChatPanel(self.unityViewNode)
    --     end
    -- )
end

--隐藏游戏内聊天面板
function RoomView:hideChatPanel()
    --HideInGameChatPanel() 需要补上
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

function RoomView:showRuleView()
    -- if self.room.disbandVoteView then
    --     return
    -- end
    -- Util.SaveToPlayerPrefs("isOpenRuleMsgBox", "1")
    -- self.ruleTipNode.visible = false
    -- self.unityViewNode:StopAction(self.fingerMoveAction1)
    -- self.RoomRuleMsgBox =
    --     viewModule:OpenMsgBox(
    --     {
    --         luaPath = "GuanZhang.Script.View.RoomRuleMsgBox",
    --         resPath = "GameModule/GuanZhang/_AssetsBundleRes/prefab/bund2/RoomRuleMsgBox.prefab"
    --     },
    --     self.room:getRoomConfig()
    -- )
end

function RoomView:closeRuleView()
    if self.RoomRuleMsgBox then
        self.RoomRuleMsgBox:Close()
    end
end

function RoomView:ShowGameRuleView()
    -- viewModule:OpenMsgBox(
    --     {
    --         luaPath = "RuleComponent.Script.RuleView",
    --         resPath = "Component/RuleComponent/Bundle/prefab/RuleView.prefab"
    --     },
    --     10045
    -- )
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

----------------------------------------------
-- 播放牌局开始动画
----------------------------------------------
function RoomView:gameStartAnimation()
    --开始骰子动画 关闭所有的弹窗
    -- if not self.room.disbandVoteView then
    --     viewModule:CloseAllMsgBox()
    -- end
    -- local waitCo = coroutine.running()
    -- dfCompatibleAPI:soundPlay("effect/effect_paijukaishi")
    --开局头像动画播放
    --self:playInfoGroupAnimation()
    -- local ani = Animator.Play(
    --     dfConfig.PATH.EFFECTS .. dfConfig.EFF_DEFINE.SUB_JIEMIAN_DUIJUKAISHI .. ".prefab",
    --     self.unityViewNode.order,
    --     nil
    -- )
    -- self.unityViewNode:DelayRun(
    --     0.2,
    --     function()
    --         -- ani.visible = false
    --         local flag, msg = coroutine.resume(waitCo)
    --         if not flag then
    --             msg = debug.traceback(waitCo, msg)
    --             --error(msg)
    --             logger.error(msg)
    --             return
    --         end
    --     end
    -- )
    -- coroutine.yield()
end

----------------------------------------------
-- 播放一手牌结束
----------------------------------------------
function RoomView:handOverAnimation()
    --Animator.Play("Effects_jiemian_duijvjiesu")
    local waitCo = coroutine.running()
    --延迟播放
    self.unityViewNode:DelayRun(
        1.2,
        function()
            -- Sound.Play("effect_paijukaishi")
            -- Animator.Play(EFF_DEFINE.SUB_PAIJUJIESHU, nil, function()
            --     local flag, msg = coroutine.resume(waitCo)
            --     if not flag then
            --         msg = debug.traceback(waitCo, msg)
            --         --error(msg)
            --         logger.error(msg)
            --         return
            --     end
            -- end)

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
--------------------------------------
--设置当前房间所等待的操作玩家
--------------------------------------
function RoomView:setWaitingPlayer(player)
    --TODO:假设客户端只允许一个等待标志
    --因此设置一个等待时，先把其他的清理掉
    self:startDiscardCountdown()
    self:clearWaitingPlayer()
    local viewChairID = player.playerView.viewChairID
    self.roundMarks[viewChairID].visible = true

    player.playerView:setHeadEffectBox(true)
end
--------------------------------------
--清除当前房间的等待玩家标志
--------------------------------------
function RoomView:clearWaitingPlayer()
    for _, mask in ipairs(self.roundMarks) do
        mask.visible = false
    end
    for _, v in pairs(self.playerViews) do
        v:setHeadEffectBox(false)
    end
end

--------------------------------------
--初始化房间号
--------------------------------------
function RoomView:initRoomNumber()
    self.roomInfoText = self.unityViewNode:GetChild("roomInfo")

    -- self.unityViewNode:AddClick(
    --     self.roomInfoNode,
    --     function()
    --         if self.room.roomNumber == nil then
    --             return
    --         end
    --         self.tipNode.visible = false
    --         -- local content = "大丰关张:房号【" .. self.room.roomNumber .. "】, " .. self:getInvitationDescription()
    --         -- Util.CopyClipboard(content)
    --         prompt.showPrompt("复制房间信息成功，你可前往其他地方粘贴发送给好友！")
    --         -- Util.SaveToPlayerPrefs("isCopyRoomNum", "1")
    --         self.unityViewNode:StopAction(self.fingerMoveAction)
    --         self.finger:Hide()
    --     end
    -- )
end

function RoomView:initRoomTip()
    -- self.scrollTip = self.unityViewNode:FindChild("ExtendFuc/ScrollTip")
    -- -- ios提审
    -- if configModule:IsIosAudit() then
    --     return
    -- end
    -- self.scrollTip.visible = true
    -- self.scrollTipText = self.scrollTip:Find("Tip")
    -- local tips = clone(dfConfig.RoomTips)
    -- local function showTip(time1, time2)
    --     if self.unityViewNode then
    --         self.unityViewNode:RunAction(
    --             self.scrollTipText,
    --             {
    --                 "fadeTo",
    --                 0,
    --                 time1,
    --                 function(...)
    --                     math.newrandomseed()
    --                     local curTipIndex = math.random(1, #tips)
    --                     self.scrollTipText.text = tips[curTipIndex]
    --                     table.remove(tips, curTipIndex)
    --                     if #tips <= 0 then
    --                         tips = clone(dfConfig.RoomTips)
    --                     end
    --                     self.unityViewNode:RunAction(self.scrollTipText, {"fadeTo", 255, time2})
    --                 end
    --             }
    --         )
    --     end
    -- end
    -- showTip(0, 2)
    -- self.unityViewNode:StartTimer(
    --     "SHowTips",
    --     5,
    --     function(...)
    --         showTip(1, 1)
    --     end,
    --     -1
    -- )
    -- self.ruleTipNode = self.unityViewNode:FindChild("ExtendFuc/TipNode")
    -- self.ruleFinger = self.ruleTipNode:Find("Finger")
    -- local isOpenRuleMsgBox = Util.GetFromPlayerPrefs("isOpenRuleMsgBox")
    -- if isOpenRuleMsgBox == "1" then --复制过房号 则隐藏
    --     self.ruleTipNode.visible = false
    -- else
    --     self.ruleTipNode.visible = true
    --     local function fingerMove(posY)
    --         self.fingerMoveAction1 =
    --             self.unityViewNode:RunAction(
    --             self.ruleFinger,
    --             {
    --                 "localMoveBy",
    --                 0,
    --                 posY,
    --                 0.5,
    --                 onEnd = function()
    --                     fingerMove(-posY)
    --                 end
    --             }
    --         )
    --     end
    --     fingerMove(20)
    -- end
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

--初始化时间 wifi信号 电量
--------------------------------------
function RoomView:initPhoneInfo()
    -- iOS提审
    -- if configModule:IsIosAudit() then
    --     return
    -- end
    -- local timeObj = self.unityViewNode.transform:Find("ExtendFuc/Time")
    -- local pingObj = self.unityViewNode.transform:Find("ExtendFuc/Ping")
    -- local wifiObj = self.unityViewNode.transform:Find("ExtendFuc/Wifi")
    -- local cmcObj = self.unityViewNode.transform:Find("ExtendFuc/CMC")
    -- local powerObj = self.unityViewNode.transform:Find("ExtendFuc/Power")
    -- timeObj.visible = true
    -- pingObj.visible = true
    -- wifiObj.visible = true
    -- cmcObj.visible = false
    -- powerObj.visible = true
    -- self.time = self.unityViewNode:SubGet("ExtendFuc/Time", "Text")
    -- self.ping = self.unityViewNode:SubGet("ExtendFuc/Ping", "Text")
    -- self.wifi = {}
    -- for i = 1, 2 do
    --     self.wifi[i] = self.unityViewNode.transform:Find("ExtendFuc/Wifi/Wifi" .. i)
    -- end
    -- self.cmc = {}
    -- for i = 1, 2 do
    --     self.cmc[i] = self.unityViewNode.transform:Find("ExtendFuc/CMC/CMC" .. i)
    -- end
    -- self.power = {}
    -- for i = 1, 3 do
    --     self.power[i] = self.unityViewNode.transform:Find("ExtendFuc/Power/Power" .. i)
    -- end
    -- local function updatePhoneInfo(...)
    --     local delay = self:getNetDelay()
    --     self.time.text = os.date("%H:%M", os.time())
    --     local battery = Util.GetBattery()
    --     local netAvailable = Util.NetAvailable
    --     local isWifi = Util.IsWifi
    --     if battery >= 90 then
    --         self.power[1].visible = true
    --         self.power[2].visible = false
    --         self.power[3].visible = false
    --     elseif battery >= 30 and battery < 90 then
    --         self.power[2].visible = true
    --         self.power[1].visible = false
    --         self.power[3].visible = false
    --     else
    --         self.power[3].visible = true
    --         self.power[2].visible = false
    --         self.power[1].visible = false
    --     end
    --     if netAvailable then
    --         if isWifi then
    --             wifiObj.visible = true
    --             cmcObj.visible = false
    --             self.ping.text = delay .. "ms"
    --             if delay > 200 then
    --                 self.ping.visible = true
    --                 self.wifi[1].visible = false
    --                 self.wifi[2].visible = true
    --             else
    --                 self.ping.visible = false
    --                 self.wifi[1].visible = true
    --                 self.wifi[2].visible = false
    --             end
    --         else
    --             wifiObj.visible = false
    --             cmcObj.visible = true
    --             self.ping.text = delay .. "ms"
    --             if delay > 200 then
    --                 self.ping.visible = true
    --                 self.cmc[1].visible = false
    --                 self.cmc[2].visible = true
    --             else
    --                 self.ping.visible = false
    --                 self.cmc[1].visible = true
    --                 self.cmc[2].visible = false
    --             end
    --         end
    --     else
    --         logger.debug("net is not Available！！")
    --     end
    -- end
    -- updatePhoneInfo()
    -- self.unityViewNode:StartTimer(
    --     "Clock",
    --     10,
    --     function(...)
    --         updatePhoneInfo()
    --     end,
    --     -1
    -- )
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
    -- msg = "确定要返回大厅吗？"
    -- local roomView = self
    -- dfCompatibleAPI:showMessageBox(
    --     msg,
    --     function()
    --         local room = roomView.room
    --         --先向服务器发送返回大厅请求
    --         room:onRetunHallClicked()
    --     end,
    --     function()
    --         --nothing to do
    --     end
    -- )
    local room = self.room
    --先向服务器发送返回大厅请求
    room:onRetunHallClicked()
end

--------------------------------------
--播放玩家开局头像动画
--------------------------------------
function RoomView:playInfoGroupAnimation()
    for _, v in ipairs(self.playerViews) do
        v:playInfoGroupAnimation()
    end
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

--------------------------------------
--重连房间界面刷新
--------------------------------------
-- function RoomView:onReconnect()
--     for i, v in ipairs(self.playerViews) do
--         v.onReconnect()
--     end
-- end
--------------------------------------
--初始化声音按钮
--------------------------------------
function RoomView:initVoiceButton()
    -- 控制逻辑
    -- self.voiceButton = self.unityViewNode.transform:Find("ExtendFuc/RightBtns/chat_audio_btn")
    -- local w = self.voiceButton.width
    -- local h = self.voiceButton.height
    -- local camera = Util.GetUICamera():GetComponent(typeof(UnityEngine.Camera))
    -- local scrPos = camera:WorldToScreenPoint(self.voiceButton.position)
    -- local rect = UnityEngine.Rect(scrPos.x - w / 2, scrPos.y - h / 2, w, h)
    -- local init = function()
    --     if not self.voiceLayer then
    --         self.voiceLayer = self:createVoiceLayer()
    --         self.voiceLayer:SetVoiceButtonRect(rect)
    --         self.voiceLayer:ResetMode()
    --     end
    -- end
    -- init() -- 初始化
    -- self.voiceButton.onDown = function()
    --     self.voiceLayer:OnVoiceButtonDown(self.room.user.userID)
    -- end
    -- self.voiceButton.onUp = function()
    --     self.voiceLayer:OnVoiceButtonUp(self.room.user.userID)
    -- end
    -- self.voiceButton.onDrag = function(sender, eventData)
    --     self.voiceLayer:OnVoiceButtonDrag(sender, eventData)
    -- end
    -- self.delayRunMap = {}
end

function RoomView:createVoiceLayer()
    -- local layer =
    --     viewModule:CreatePanel(
    --     {
    --         luaPath = "VoiceComponent.Script.VoiceLayer",
    --         resPath = "Component/VoiceComponent/Bundle/prefab/VoiceLayer.prefab",
    --         superClass = self.unityViewNode,
    --         parentNode = self.unityViewNode.transform
    --     }
    -- )
    -- local uiDepth = layer:GetComponent("UIDepth")
    -- if not uiDepth then
    --     uiDepth = layer:AddComponent(UIDepth)
    -- end
    -- uiDepth.canvasOrder = self.unityViewNode.order + 2
    -- return layer
end

----------------------------------------------------------
--初始化房间状态事件
----------------------------------------------------------
function RoomView:initRoomStatus()
    -- 房间正在等待玩家准备
    local onWait = function()
        self.wind.visible = false
        self.windTile.visible = false

        self.roundMarkView.visible = false
        self:stopDiscardCountdown()
        --等待状态重置上手牌遗留
        self.room:resetForNewHand()
        --roomView.tilesInWall.visible = false

        -- local config = self.room:getRoomConfig()
        -- if config ~= nil then
        --     logger.debug(" players:", room:playerCount(), ", required:", config.playerNumAcquired)
        --     if room:playerCount() >= config.playerNumAcquired then
        --         roomView.invitButton.visible = false
        --     else
        --         -- IOS 提审
        --         -- if configModule:IsIosAudit() then
        --         --     roomView.invitButton.visible = false
        --         -- end
        --         roomView.invitButton.visible = true
        --     end
        -- end

        -- roomView:updateLeaveAndDisbandButtons()
    end

    --房间空闲，客户端永远看不到这个状态
    local onIdle = function()
    end

    -- 游戏开始了
    local onPlay = function()
        -- roomView.invitButton.visible = false
        -- roomView.returnHallBtn.visible = false
        self.wind.visible = false --发牌的时候，或者掉线恢复的时候会设置风圈因此此处不需要visible
        self.windTile.visible = false

        self.roundMarkView.visible = true
        self:clearWaitingPlayer()
        --if not room:isReplayMode() then
        --<color=#775D42FF>" .. formatStr .. "</color>
        -- local roundstr = "局数:<color=#e9bf89>%s/%s</color>"
        --roomView.tilesInWall.visible = true
        -- roomView.tipNode.visible = false
        -- roomView.ruleTipNode.visible = false
        self:showRoomNumber()
        -- else
        --     roomView.curRound.visible = false
        --     roomView.totalRound.visible = false
        -- end
        -- roomView:updateLeaveAndDisbandButtons()
        -- self.scrollTip:Hide()
        -- self.unityViewNode:StopTimer("SHowTips")
        -- self.unityViewNode:StopAction(self.fingerMoveAction)
        -- self.unityViewNode:StopAction(self.fingerMoveAction1)
        -- self:hideNoFriendTips()
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
        self.exitBtn.visible = false
        self.dissolveBtn.visible = true
        return
    end
    self.exitBtn.visible = true
    self.dissolveBtn.visible = false
    -- if room.ownerID == room:me().userID then
    --     self.exitBtn.visible = true
    --     self.dissolveBtn.visible = false
    -- else
    --     self.exitBtn.visible = true
    --     self.dissolveBtn.visible = false
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

----------------------------------------------------------
--初始化房间规则显示
----------------------------------------------------------
function RoomView:initRoomRule()
    local textRoomID = self.unityViewNode:SubGet("RuleTop/RoomID", "Text")
    if self.room.roomInfo ~= nil and self.room.roomInfo.roomNumber ~= nil then
        textRoomID.text = "房号:" .. self.room.roomInfo.roomNumber
    end

    local textRule = self.unityViewNode:SubGet("RuleTop/Rule", "Text")
    local isLoadDouble = false
    textRule.text = self:getRule(isLoadDouble)

    self.addedRule = self.unityViewNode.transform:Find("RuleTop/RuleNode")
    self.addedRuleText = self.unityViewNode:SubGet("RuleTop/RuleNode/RuleAdd", "Text")
    self.addedRule.visible = false

    -- 点击房间顶部信息事件
    self.unityViewNode:AddClick(
        "RuleTop",
        function()
            self:ruleTopDisplayEvent()
        end
    )
    -- 点击房间顶部小箭头事件
    self.unityViewNode:AddClick(
        "RuleTop/Arrow",
        function()
            self:ruleTopDisplayEvent()
        end
    )
    local room = self.room
    if room:isReplayMode() then
        self:showRoomNumber()
    end
end

function RoomView:ruleTopDisplayEvent()
    local config = self.room:getRoomConfig()

    local isdDoubleScoreWhenSelfDrawn = config.doubleScoreWhenSelfDrawn ~= nil and config.doubleScoreWhenSelfDrawn
    local dscb = config.doubleScoreWhenContinuousBanker ~= nil and config.doubleScoreWhenContinuousBanker
    local isDoubleScoreWhenContinuousBanker = dscb

    local isDoubleScoreWhenZuoYuanZi = config.doubleScoreWhenZuoYuanZi ~= nil and config.doubleScoreWhenZuoYuanZi
    local isAA = config.payType

    if self.addedRule.activeSelf == false then
        local rules = ""

        if isAA == 1 then
            rules = rules .. "钻石平摊"
        else
            rules = rules .. "房主支付"
        end

        if isdDoubleScoreWhenSelfDrawn then
            rules = rules .. " 自摸加双"
        end

        if isDoubleScoreWhenContinuousBanker then
            rules = rules .. " 连庄"
        end

        -- 坐园子
        if isDoubleScoreWhenZuoYuanZi then
            rules = rules .. " 坐园子"
        end

        self.addedRuleText.text = rules
        self.addedRule.visible = true
    else
        self.addedRule.visible = false
    end
end

-- --------------------------------------------------------
-- 邀请好友进入游戏
-- --------------------------------------------------------
function RoomView:getInvitationDescription()
    local rule = ""
    local config = self.room:getRoomConfig()
    local players = self.room.players
    local playerNumber = #players

    -- local playerNumAcquired = ""
    local p = ""
    if config ~= nil then
        if config.playerNumAcquired ~= nil then
            if config.playerNumAcquired == 2 then
                p = "二"
            elseif config.playerNumAcquired == 3 then
                p = "三"
            elseif config.playerNumAcquired == 4 then
                p = "四"
            end
            rule = rule .. p .. "人场，"
        end

        if playerNumber ~= nil then
            local b = config.playerNumAcquired - playerNumber
            local n = ""
            if b == 1 then
                n = "1"
            elseif b == 2 then
                n = "2"
            elseif b == 3 then
                n = "3"
            end
            rule = rule .. p .. "缺" .. n .. "，"
        end

        if config.handNum ~= nil then
            rule = rule .. tostring(config.handNum) .. "局，"
            self.room.handNum = config.handNum
        end

        if config.payType ~= nil then
            local s = " 房主支付"
            if config.payType == 1 then
                s = " 钻石平摊"
            end
            rule = rule .. s
        end

        if config.fengDingType ~= nil then
            local s = "封顶100/200/300"
            if config.fengDingType == 0 then
                s = "封顶20/40"
            elseif config.fengDingType == 1 then
                s = "封顶30/60"
            elseif config.fengDingType == 2 then
                s = "封顶50/100/150"
            elseif config.fengDingType == 3 then
                s = "封顶100/200/300"
            end
            rule = rule .. "，" .. s
        end

        if config.dunziPointType ~= nil then
            local s = "墩子1分/2分"
            if config.dunziPointType == 1 then
                s = "墩子2分/4分"
            end
            if config.dunziPointType == 2 then
                s = "墩子5分/10分/15分"
            end
            if config.dunziPointType == 3 then
                s = "墩子10分/20分/30分"
            end
            rule = rule .. "，" .. s
        end

        if config.doubleScoreWhenSelfDrawn ~= nil and config.doubleScoreWhenSelfDrawn then
            rule = rule .. "，自摸加双"
        end
        if config.doubleScoreWhenContinuousBanker ~= nil and config.doubleScoreWhenContinuousBanker then
            rule = rule .. "，连庄"
        end

        if config.doubleScoreWhenZuoYuanZi ~= nil and config.doubleScoreWhenZuoYuanZi then
            rule = rule .. ", 坐园子"
        end

        rule = rule .. "大丰关张，大丰人最喜爱的纸牌游戏，仅此一家！"

        logger.debug("llwant , RoomView:getInvitationDescription rule : ", rule)
    end
    return rule
end

----------------------------------------------------------
--获取房间规则
----------------------------------------------------------
function RoomView:getRule(isLoadDouble)
    local rule = ""
    local config = self.room:getRoomConfig()

    if config ~= nil then
        -- if config.playerNumAcquired ~= nil then
        --     rule = rule ..tostring(config.playerNumAcquired).."人场"
        -- end

        if config.handNum ~= nil then
            rule = rule .. tostring(config.handNum) .. "局"
            self.room.handNum = config.handNum
        end

        if config.fengDingType ~= nil then
            local s = "封顶100/200/300"
            if config.fengDingType == 0 then
                s = "封顶20/40"
            elseif config.fengDingType == 1 then
                s = "封顶30/60"
            elseif config.fengDingType == 2 then
                s = "封顶50/100/150"
            end
            rule = rule .. " " .. s
        end

        if config.dunziPointType ~= nil then
            local s = "墩子1/2"
            if config.dunziPointType == 1 then
                s = "墩子2/4"
            elseif config.dunziPointType == 2 then
                s = "墩子5/10/15"
            elseif config.dunziPointType == 3 then
                s = "墩子10/20/30"
            end
            rule = rule .. " " .. s
        end

        if isLoadDouble then
            if config.payType ~= nil then
                local s = " 房主支付"
                if config.payType == 1 then
                    s = " 钻石平摊"
                end
                rule = rule .. s
            end

            if config.doubleScoreWhenSelfDrawn ~= nil and config.doubleScoreWhenSelfDrawn then
                rule = rule .. " 自摸加双"
            end
            if config.doubleScoreWhenContinuousBanker ~= nil and config.doubleScoreWhenContinuousBanker then
                rule = rule .. " 连庄"
            end

            if config.doubleScoreWhenZuoYuanZi ~= nil and config.doubleScoreWhenZuoYuanZi then
                rule = rule .. " 坐园子"
            end
        end
    end

    return rule
end

--------------------------------------
--显示出牌提示箭头
--------------------------------------
function RoomView:setArrowByParent(btn)
    local pos = btn:GetChild("pos")
    local x = pos.x
    local y = pos.y
    self.arrowObj = animation.play("animations/Effects_UI_jiantou.prefab", btn, x, y, true)
    self.arrowObj.wrapper.scale = pos.scale
    self.arrowObj.setVisible(true)
    -- if self.arrowObj then
    --     self.arrowObj:SetParent(parentObj, false)
    --     --self.arrowObj.localPosition = Vector3(0, 0, 0)
    --     self.arrowObj.localPosition = Vector3(0, 40, 0)
    --     -- 这里不需要设置显不显示，因为会在SetOneOutCardShowByID中调用SetOutCardAni时让它显示出来的
    --     self.arrowObj:Show()
    -- -- 这里主要用来判断自摸的时候，隐藏上一家的打牌的箭头，如果是打牌出去，会在之后的代码中被显示出来。
    -- --self.arrowObj:Hide()
    -- end
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

--------------------------------------
--隐藏听牌详情界面
--------------------------------------
function RoomView:hideTingDataView()
    self.listensObj.visible = false
end
--------------------------------------
--显示听牌详情界面
--------------------------------------
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

--------------------------------------
--初始化显示听牌详情界面
--------------------------------------
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

return RoomView
