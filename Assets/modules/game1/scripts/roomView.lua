--[[
    房间的view，大致上这样划分：凡是属于用户相关的，就放到PlayerView，其余的放到RoomView中
]]
local RoomView = {}

local fairy = require "lobby/lcore/fairygui"
local PlayerView = require("scripts/playerView")
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

pkproto2 = pkproto2

local function onVoiceClick(context)
    print("you click on onVoiceClick ")
end

local function onSettingClick(context)
    print("you click on onSettingClick")
end

function RoomView.new(room)
    _ENV.thisMod:AddUIPackage("lobby/fui_lobby_poker/lobby_poker")
    _ENV.thisMod:AddUIPackage("game1/bg/runfast_bg_2d")
    _ENV.thisMod:AddUIPackage("game1/fgui/runfast")
    _ENV.thisMod:AddUIPackage("game1/setting/runfast_setting")
    local view = fairy.UIPackage.CreateObject("runfast", "desk")
    fairy.GRoot.inst:AddChild(view)
    local operationPanel = view:GetChild("n31")

    local roomView = {}

    roomView.room = room
    roomView.unityViewNode = view

    -- 根据prefab中的位置，正中下方是Cards/P1，左手是Cards/P4，右手是Cards/P2，正中上方是Cards/P3
    local playerViews = {}
    for i = 1, 3 do
        local playerView = PlayerView:new(roomView.unityViewNode, i)
        -- playerView:hideAll()
        playerViews[i] = playerView
    end

    roomView.playerViews = playerViews

    roomView.leftPlayerView = playerViews[3]
    roomView.rightPlayerView = playerViews[2]
    roomView.downPlayerView = playerViews[1]

    local unityViewNode = roomView.unityViewNode

    local voiceBtn = unityViewNode:GetChild("voice")
    voiceBtn.onClick:Add(onVoiceClick)
    voiceBtn.visible = false

    local settingBtn = unityViewNode:GetChild("setting")
    settingBtn.onClick:Add(onSettingClick)

    local infoBtn = unityViewNode:GetChild("info")
    infoBtn.visible = true
    -- -- 长按10秒上传日志文件
    -- unityViewNode:AddLongPressClick(
    --     roomView.PostLogBtn,
    --     function()
    --         local toolModule = g_ModuleMgr:GetModule(ModuleName.TOOLLIB_MODULE)
    --         local logType = 3
    --         local subGameId = 10034
    --         toolModule:UploadLogFile(
    --             function(data)
    --                 if data.result == 0 and g_commonModule then
    --                     g_commonModule:ShowTip("日志文件已上传", 2)
    --                 end
    --             end,
    --             logType,
    --             subGameId
    --         )
    --     end,
    --     5
    -- )

    -- unityViewNode:AddClick(
    --     roomView.readyButton,
    --     function()
    --         roomView:onReadyButtonClick()
    --     end
    -- )
    -- unityViewNode:AddClick(
    --     roomView.invitButton,
    --     function()
    --         roomView:onInvitButtonClick()
    --     end
    -- )
    -- unityViewNode:AddClick(
    --     roomView.returnHallBtn,
    --     function()
    --         roomView:onRetunHallClick()
    --     end
    -- )

    -- roomView.skinManager = SkinManager.GetInstance()

    -- --计时器
    -- roomView.timer = {}

    -- --启动聊天面板监听
    -- -- require("View/ChatPanelInGame")

    -- roomView:initRoomSkin()

    -- self.skinIndex = unityViewNode.skinIndex

    -- 聊天
    -- roomView:iniChatButtons()
    -- -- 语音
    -- roomView:initVoiceButton()
    -- --菜单
    -- roomView:initMenu()
    -- --房间号
    -- roomView:initRoomNumber()
    -- --手机基本信息
    -- roomView:initPhoneInfo()
    -- --房间温馨提示
    -- roomView:initRoomTip()

    -- --房间状态事件初始化
    -- roomView:initRoomStatus()

    -- -- 房间规则
    -- roomView:initRoomRule()
    -- -- GPS
    -- roomView:initDistanceView()
    -- 隐藏空椅子
    --roomView:hideEmptyChair()

    --注册消息通知
    --notificationCenter:register(self, self.OnMessage, Notifications.OnInGameChatMessage)
    --notificationCenter:register(self, OnPlayerChat, "PlayerChat") --收到聊天信息

    -- if room:isReplayMode() then
    --     local extendFunc = unityViewNode.transform:Find("ExtendFuc")
    --     extendFunc:SetActive(false)

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
    --     resumeBtn:SetActive(false)
    --     pauseBtn:SetActive(false)

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

    -- roomView:registerBroadcast()
    -- if g_dataModule:GetAntiAddiction() then
    --     local data = g_dataModule:GetAntiAddiction()
    --     roomView:AntiAddiction(data.fillIn, data.onlineTime)
    -- end
    -- logger.debug("进入子游戏关张房间完成，当前系统时间：" .. os.time())
    return setmetatable(roomView, mt)
end
--gps
function RoomView:initDistanceView()
    self.distanceView = self.unityViewNode.transform:Find("DistanceView")
    self.distanceViewGroup = {}
    for i = 1, 3 do
        local item = {}
        -- item.name = self.unityViewNode:SubGet("DistanceView/Players/"..i, "Text")
        -- item.ip = self.unityViewNode:SubGet("DistanceView/Players/"..i.."/TextIp", "Text")
        item.gpstoggle = self.unityViewNode:SubGet("DistanceView/Toggle" .. i, "Toggle")
        --item.gpstip = self.unityViewNode:FindChild("DistanceView/Toggle" .. i .. "/Text", "Text")
        table.insert(self.distanceViewGroup, item)
    end

    self.distanceViewSafeLines = {}
    self.distanceViewWarnLines = {}

    for i = 1, 3 do
        self.distanceViewSafeLines[i] = self.unityViewNode:FindChild("DistanceView/LineSafe/" .. i)
        self.distanceViewWarnLines[i] = self.unityViewNode:FindChild("DistanceView/LineWarn/" .. i)
    end
end
--刷新gps界面
function RoomView:updateDistance()
    if configModule:IsIosAudit() then
        return
    end

    local room = self.room
    if room == nil then
        return
    end
    local locations = {}
    local ips = {}
    local playerNumber = 0
    for i = 1, 3 do
        local player = room:getPlayerByChairID(i - 1)
        local yyy = room:getPlayerViewChairIDByChairID(i - 1) --获取此player 相对于 本玩家的 偏移位置
        if player ~= nil then
            playerNumber = playerNumber + 1
            local locationJson = player.location
            local location = {address = "对方未开启定位", lat = 0.0, lng = 0.0, IsGPS = false}
            --logError("updateGPSBtnStatus locationJson : "..locationJson)
            if locationJson ~= nil and #locationJson > 20 then
                location = Json.decode(locationJson)
            end
            --local location = Json.decode(locationJson)
            locations[yyy] = location
            ips[yyy] = player.ip

            local status = location.IsGPS
            self.distanceViewGroup[yyy].gpstoggle.transform:Show()
        else
            self.distanceViewGroup[yyy].gpstoggle.transform:Hide()
        end
    end
    if playerNumber < 2 then
        self.distanceView:SetActive(false)
        return
    end
    local distance = room:getDistance(locations, ips)
    for i = 1, 3 do
        local safe = distance[i]
        -- -1 空 ， 0 安全 ，1 距离100 ，2 ip相同 ，3 ip与距离
        if safe == 0 then
            self.distanceViewSafeLines[i]:SetActive(true)
            self.distanceViewWarnLines[i]:SetActive(false)
        else
            self.distanceViewSafeLines[i]:SetActive(false)
            local str = ""
            if safe == 2 then
                str = "IP相同"
                self.distanceViewWarnLines[i]:SetActive(true)
                self:setBreathingEffect(self.distanceViewWarnLines[i], i)
            elseif safe == 1 then
                str = "距离小于20米"
                self.distanceViewWarnLines[i]:SetActive(true)
                self:setBreathingEffect(self.distanceViewWarnLines[i], i)
            elseif safe == 3 then
                str = "IP相同 距离小于20米"
                self.distanceViewWarnLines[i]:SetActive(true)
                self:setBreathingEffect(self.distanceViewWarnLines[i], i)
            else
                self.distanceViewWarnLines[i]:SetActive(false)
            end
            local text = self.distanceViewWarnLines[i]:SubGet("Text", "Text")
            text.text = str
        end
    end
    self.distanceView:SetActive(true)
end

function RoomView:hideDistanceView()
    self.distanceView:SetActive(false)
end

-- gps距离警告线呼吸效果
function RoomView:setBreathingEffect(iterm, i)
    local uiTweenAlpha = iterm:GetComponent("UITweenAlpha")
    if uiTweenAlpha == nil then
        logger.debug(" uiTweenAlpha is nil ")
        return
    else
        uiTweenAlpha.enabled = true
    end

    self.unityViewNode:StartTimer(
        "BreathEffect" .. i,
        3,
        function()
            uiTweenAlpha.enabled = false
            self.unityViewNode:StopTimer("BreathEffect" .. i)
        end,
        1
    )
end

function RoomView:pauseResumeButtons(pauseBtnVisible, resumeBtnVisible)
    self.pauseBtn:SetActive(pauseBtnVisible)
    self.resumeBtn:SetActive(resumeBtnVisible)
end

function RoomView:destroyReplayView()
    self.replayUnityViewNode:Destroy()
end

function RoomView:BackRoom()
    --notificationCenter:unregister(self, Notifications.OnInGameChatMessage)
    --notificationCenter:unregister(self, "PlayerChat")
end

function RoomView:show2ReadyButton()
    self.readyButton:SetActive(true)
end

function RoomView:hide2ReadyButton()
    self.readyButton:SetActive(false)
end

function RoomView:onReadyButtonClick()
    local room = self.room
    local host = room.host

    host:sendPlayerReadyMsg()
end

function RoomView:onInvitButtonClick()
    self:ShowInviteFriendsView()
end

--打开邀请好友界面
function RoomView:ShowInviteFriendsView()
    local title = "闲雅大丰关张:房号【" .. self.room.roomNumber .. "】"
    local contentStr = self:getInvitationDescription()

    local shareUrl = g_commonModule:GetShareUrl()

    local fEncodeUri = function(s)
        s =
            string.gsub(
            s,
            "([^%w%.%- ])",
            function(c)
                return string.format("%%%02X", string.byte(c))
            end
        )
        return string.gsub(s, " ", "+")
    end

    local password = "0"
    local arenaId = "0"

    local param = string.format('{"RoomId":%s,"Password":%s,"ArenaId":%s}', self.room.roomNumber, password, arenaId)
    local url =
        shareUrl ..
        string.format("WeixinInvitedContent=%s&GameID=%s&UserID=%s", fEncodeUri(param), GameId, self.room.user.userID)
    --local url = shareUrl .. string.format("GameID=%s&UserID=%s", GameId, self.room.user.userID)
    g_ModuleMgr:GetModule(ModuleName.SHARE_MODULE):Share(
        1,
        title,
        contentStr,
        -- "Component/CommonComponent/Bundle/image/WxShareIcon.png",
        "GameModule/GuanZhang/_AssetsBundleRes/image/shareIcon/GZShareIcon.png",
        url,
        1
    )
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
function RoomView:openChatView()
    local singleton = require(dfPath .. "dfMahjong/dfSingleton")
    local instance = singleton:getSingleton()

    local layer =
        viewModule:CreatePanel(
        {
            luaPath = "ChatComponent.Script.ChatView",
            resPath = "Component/ChatComponent/Bundle/prefab/ChatPanelInGame.prefab",
            superClass = self.unityViewNode,
            parentNode = self.unityViewNode.transform
        },
        instance,
        dfConfig.CommonLanguage
    )
    local uiDepth = layer:GetComponent("UIDepth")
    if not uiDepth then
        uiDepth = layer:AddComponent(UIDepth)
    end
    uiDepth.canvasOrder = self.unityViewNode.order + 2
    return layer
end

function RoomView:iniChatButtons()
    self.chatTextBtn = self.unityViewNode.transform:Find("ExtendFuc/RightBtns/chat_text_btn")
    --self.PengBtn:SetActive(false)
    -- initChatPanelInGame()
    self.chatView = self:openChatView()
    self.chatView:Hide()

    self.unityViewNode:AddClick(
        self.chatTextBtn,
        function()
            if not self.chatView then
                self.chatView = self:openChatView()
            else
                self.chatView:Show()
            end
            --ShowInGameChatPanel(self.unityViewNode)
        end
    )
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
        dfCompatibleAPI:showTip("牌局已经开始，请申请解散房间")
        return
    end

    local room = roomView.room
    local me = room:me()

    -- local aaModel = 1
    -- if roomView.room ~= nil then
    --     local roomConfig = roomView.room:getRoomConfig()
    --     if roomConfig.payType == aaModel then
    --         if room.ownerID == me.userID then
    --             dfCompatibleAPI:showTip("平摊钻石房间，请申请解散房间")
    --             return
    --         end
    --     end
    -- end

    msg = "确实要退出房间吗？"
    dfCompatibleAPI:showMessageBox(
        msg,
        function()
            local room = roomView.room
            --先向服务器发送退出房间请求

            room.host:triggerLeaveRoom()
        end,
        function()
            --nothing to do
        end
    )
end

function RoomView:showRuleView()
    if self.room.disbandVoteView then
        return
    end
    Util.SaveToPlayerPrefs("isOpenRuleMsgBox", "1")
    self.ruleTipNode:SetActive(false)
    self.unityViewNode:StopAction(self.fingerMoveAction1)
    self.RoomRuleMsgBox =
        viewModule:OpenMsgBox(
        {
            luaPath = "GuanZhang.Script.View.RoomRuleMsgBox",
            resPath = "GameModule/GuanZhang/_AssetsBundleRes/prefab/bund2/RoomRuleMsgBox.prefab"
        },
        self.room:getRoomConfig()
    )
end

function RoomView:closeRuleView()
    if self.RoomRuleMsgBox then
        self.RoomRuleMsgBox:Close()
    end
end
--------------------------------------
--初始化菜单按钮以及菜单面板
--------------------------------------
function RoomView:initMenu()
    -- 菜单面板
    self.menuPanel = self.unityViewNode.transform:Find("MenuPanel")
    local uiDepth = self.menuPanel:GetComponent("UIDepth")
    if not uiDepth then
        uiDepth = self.menuPanel:AddComponent(typeof(UIDepth))
    end
    uiDepth.canvasOrder = self.unityViewNode.order + 2

    self.classicBg = self.menuPanel:Find("ClassicBg")
    self.commonBg = self.menuPanel:Find("CommonBg")
    self.exitBtn = self.menuPanel:Find("ExitBtn")
    self.dissolveBtn = self.menuPanel:Find("DissolveBtn")
    self.ruleBtn = self.menuPanel:Find("RuleBtn")
    self.effectSlider = self.menuPanel:Find("EffectSlider"):GetComponent("Slider")
    self.musicSlider = self.menuPanel:Find("MusicSlider"):GetComponent("Slider")

    self.mark = self.menuPanel:Find("Mark")

    local soundMedule = g_ModuleMgr:GetModule(ModuleName.SOUND_MODULE)
    local effect = soundMedule.effectVolume or 1
    local music = soundMedule.backMusicVolume or 0.3
    self.effectSlider.value = effect
    self.musicSlider.value = music

    UIEvent.AddSliderOnValueChange(
        self.musicSlider.transform,
        function(v)
            soundMedule:SetBackMusicVolume(v)
        end
    )
    UIEvent.AddSliderOnValueChange(
        self.effectSlider.transform,
        function(v)
            soundMedule:SetEffectVolume(v)
        end
    )

    -- 关闭菜单按钮事件
    self.unityViewNode:AddClick(
        self.mark,
        function()
            if self.menuPanel.activeSelf then
                self.menuPanel:Hide()
            end
        end
    )

    -- 菜单按钮点击事件
    self.unityViewNode:AddClick(
        "ExtendFuc/TopBtns/menu_btn",
        function()
            if not self.menuPanel.activeSelf then
                self.menuPanel:Show()
            end
        end
    )
    -- 规则按钮事件
    self.unityViewNode:AddClick(
        "ExtendFuc/TopBtns/rule_btn",
        function()
            self:showRuleView()
        end
    )

    -- 关闭菜单按钮事件
    self.unityViewNode:AddClick(
        self.menuPanel:Find("CloseBtn"),
        function()
            if self.menuPanel.activeSelf then
                self.menuPanel:Hide()
            end
        end
    )
    self.unityViewNode:AddClick(
        self.menuPanel:Find("CloseBtn1"),
        function()
            if self.menuPanel.activeSelf then
                self.menuPanel:Hide()
            end

            Native.GotoGPSSet()
        end
    )
    -- 桌面背景事件
    self.unityViewNode:AddClick(
        "BgImage",
        function()
            if self.menuPanel.activeSelf then
                self.menuPanel:Hide()
            end
            --TODO: 暂时加上：如果手牌处于被选中状态，恢复到原始位置
            local player = self.room:me()
            if player ~= nil then
                player.playerView:restoreHandPositionAndClickCount(0)
            end
            -- 隐藏房间顶部额外信息
            if self.addedRule.activeSelf == true then
                self.addedRule:SetActive(false)
            end
        end,
        {isMute = true}
    )

    -- 解散按钮
    self.exitBtn:SetActive(true)
    self.dissolveBtn:SetActive(false)
    -- 解散按钮点击事件
    self.unityViewNode:AddClick(
        self.dissolveBtn,
        function()
            self:onDissolveClick()
            self.menuPanel:Hide()
        end
    )

    --退出按钮
    self.unityViewNode:AddClick(
        self.exitBtn,
        function()
            if self.room.ownerID == self.room:me().userID then
                self:onDissolveClick()
            else
                self:onExitButtonClicked()
            end
            self.menuPanel:Hide()
        end
    )

    --本局规则
    self.unityViewNode:AddClick(
        self.ruleBtn,
        function()
            self:ShowGameRuleView()
            --self.menuPanel:Hide()
        end
    )
    self:UpdateBgStyle(self.skinIndex)

    self.unityViewNode:AddClick(
        self.classicBg,
        function()
            if self.skinIndex ~= 1 then
                self:UpdateBgStyle(1)
                self:initRoomSkin(1)
                userDataModule:Save("accountCfg", "skinIndex", "1")
            end
        end
    )
    self.unityViewNode:AddClick(
        self.commonBg,
        function()
            if self.skinIndex ~= 2 then
                self:UpdateBgStyle(2)
                self:initRoomSkin(2)
                userDataModule:Save("accountCfg", "skinIndex", "2")
            end
        end
    )
end

function RoomView:ShowGameRuleView()
    viewModule:OpenMsgBox(
        {
            luaPath = "RuleComponent.Script.RuleView",
            resPath = "Component/RuleComponent/Bundle/prefab/RuleView.prefab"
        },
        10045
    )
end

function RoomView:UpdateBgStyle(index)
    if index == 1 then
        self.classicBg:SetImage("GameModule/GuanZhang/_AssetsBundleRes/image/common/jds.png")
        self.commonBg:SetImage("GameModule/GuanZhang/_AssetsBundleRes/image/common/pls_hui.png")
    else
        self.classicBg:SetImage("GameModule/GuanZhang/_AssetsBundleRes/image/common/jds_hui.png")
        self.commonBg:SetImage("GameModule/GuanZhang/_AssetsBundleRes/image/common/pls.png")
    end
end

--------------------------------------
--显示GPS距离界面
--------------------------------------
function RoomView:showGPSDistanceView(isSafe, updatePlayer)
    --如果mLZDistanceView 显示着，则不管参数，直接刷新
    --如果mLZDistanceView 未显示，则判断updatePlayer是否为1(表示有人加入) ，再判断isSafe是否为false  都成立则显示
    -- IOS 提审
    if self.distanceView.activeSelf then
        --if self.mLZDistanceView ~= nil then
        --ViewManager.CloseMessageBox()
        --self.mLZDistanceView:Destroy()
        --self.mLZDistanceView = nil
        --self.mLZDistanceView
    else
        if updatePlayer ~= 1 or isSafe then
            return
        end
    end
    self:updateDistance()
    --self.mLZDistanceView = ViewManager.OpenMessageBox("LZDistanceView", self.room)

    -- local viewModule = g_ModuleMgr:GetModule(ModuleName.VIEW_MODULE)
    -- local viewObj = viewModule:OpenMsgBox({
    --     luaPath = dfPath .. "View/LZDistanceView",
    --     resPath = "GameModule/GuanZhang/_AssetsBundleRes/prefab/bund2/LZDistanceView.prefab"
    -- })

    -- local DfDistanceView = require ( dfPath .. "dfMahjong/dfDistanceView")
    -- local dfDistanceView = DfDistanceView:new(self.room,viewObj)
    -- self.dfDistanceView = dfDistanceView
    --self.mLZDistanceView = self.room:openMessageBoxFromDaFengNoOrder("LZDistanceView", self.room)
end

--------------------------------------
--初始化发牌动画，从LZOnlineView拷贝过来的
--------------------------------------
-- function RoomView:initFapaiAnimation()
--     --获取子物体
--     local fnFindChild = function(obj, name)
--         local t = {}
--         t[1] = obj:Find(name)
--         for i = 2, 5 do
--             t[i] = obj:Find(name .. tostring(i))
--         end
--         return t
--     end
--     local animationObj =
--         g_ModuleMgr:GetModule(ModuleName.TOOLLIB_MODULE):UguiAddChild(self.FaPaiAniObj, self.FaPaiAniPref)
--     self.tFaPaiAniNaCard[1] = fnFindChild(animationObj, "xia")
--     self.tFaPaiAniNaCard[2] = fnFindChild(animationObj, "you")
--     self.tFaPaiAniNaCard[3] = fnFindChild(animationObj, "zuo")
--     animationObj:SetActive(true)
--     return animationObj
-- end

--------------------------------------
--隐藏所有节点，从LZOnlineView拷贝过来的
--------------------------------------
function RoomView:CommonHideAll(tTable)
    if tTable == nil then
        return
    end
    for _, v in pairs(tTable) do
        if v then
            v:SetActive(false)
        end
    end
end
----------------------------------------------
-- 播放发牌动画
----------------------------------------------
function RoomView:dealAnimation(me, player1, player2)
    local waitCo = coroutine.running()

    dfCompatibleAPI:soundPlay("effect/effect_fapai")

    --self.FaPaiAniObj:Show()
    me.playerView:deal()
    player1.playerView:dealOther()
    player2.playerView:dealOther()

    self.unityViewNode:DelayRun(
        1,
        function()
            self.FaPaiAniObj:Hide()
            local flag, msg = coroutine.resume(waitCo)
            if not flag then
                msg = debug.traceback(waitCo, msg)
                --error(msg)
                logError(msg)
                return
            end
        end
    )

    coroutine.yield()
end
----------------------------------------------
-- 播放发牌动画
----------------------------------------------
-- function RoomView:dealAnimation()
--     local waitCo = coroutine.running()

--     for i = 1, 3 do
--         self:CommonHideAll(self.tFaPaiAniNaCard[i])
--     end

--     self.FaPaiAniObj:Show()
--     local aniObj = self:initFapaiAnimation()
--     dfCompatibleAPI:soundPlay("animator_fapai")

--     for i = 1, 3 do
--         local playerView = self.playerViews[i]
--         local t = self.tFaPaiAniNaCard[i]
--         if playerView.player ~= nil then
--             for i = 1, 3 do
--                 t[i]:SetActive(true)
--             end
--         else
--             for i = 1, 3 do
--                 t[i]:SetActive(false)
--             end
--         end

--         --logger.debug('llwant banker chair id = ' .. self.room.bankerChairID)
--         --拿牌动画
--         t[5]:SetActive(self.room.bankerChairID + 1 == i)
--     end

--     self.unityViewNode:DelayRun(
--         dfConfig.ANITIME_DEFINE.FAPAIANIPLAYTIME,
--         function()
--             self.FaPaiAniObj:Hide()
--             aniObj.gameObject:Destroy()
--             self.tFaPaiAniNaCard = {{}, {}, {}, {}}

--             local flag, msg = coroutine.resume(waitCo)
--             if not flag then
--                 msg = debug.traceback(waitCo, msg)
--                 --error(msg)
--                 logError(msg)
--                 return
--             end
--         end
--     )

--     coroutine.yield()
-- end
----------------------------------------------
-- 播放骰子动画
----------------------------------------------
function RoomView:touZiStartAnimation(dice1, dice2)
    -- local waitCo = coroutine.running()
    -- local touzi1 =
    --     Animator.Play(
    --     dfConfig.PATH.EFFECTS .. dfConfig.EFF_DEFINE.SUB_TOUZI_NAME .. dice1 .. ".prefab",
    --     self.unityViewNode.order,
    --     function()
    --         --开始的时候播放骰子音效
    --         dfCompatibleAPI:soundPlay("effect/effect_saizi")
    --     end
    -- )
    -- touzi1.transform.localPosition = Vector3(-25, 16, 0)
    -- local touzi2 =
    --     Animator.Play(
    --     dfConfig.PATH.EFFECTS .. dfConfig.EFF_DEFINE.SUB_TOUZI_NAME .. dice2 .. ".prefab",
    --     self.unityViewNode.order,
    --     nil,
    --     function()
    --     end
    -- )
    -- self.unityViewNode:DelayRun(
    --     0.8,
    --     function()
    --         touzi1:SetActive(false)
    --         touzi2:SetActive(false)
    --         local flag, msg = coroutine.resume(waitCo)
    --         if not flag then
    --             msg = debug.traceback(waitCo, msg)
    --             --error(msg)
    --             logError(msg)
    --             return
    --         end
    --     end
    -- )
    -- touzi2.transform.localPosition = Vector3(25, 16, 0)
    -- coroutine.yield()
end
----------------------------------------------
-- 播放牌局开始动画
----------------------------------------------
function RoomView:gameStartAnimation()
    --开始骰子动画 关闭所有的弹窗
    if not self.room.disbandVoteView then
        viewModule:CloseAllMsgBox()
    end
    local waitCo = coroutine.running()

    dfCompatibleAPI:soundPlay("effect/effect_paijukaishi")

    --开局头像动画播放
    --self:playInfoGroupAnimation()
    -- local ani = Animator.Play(
    --     dfConfig.PATH.EFFECTS .. dfConfig.EFF_DEFINE.SUB_JIEMIAN_DUIJUKAISHI .. ".prefab",
    --     self.unityViewNode.order,
    --     nil
    -- )

    self.unityViewNode:DelayRun(
        0.2,
        function()
            -- ani:SetActive(false)
            local flag, msg = coroutine.resume(waitCo)
            if not flag then
                msg = debug.traceback(waitCo, msg)
                --error(msg)
                logError(msg)
                return
            end
        end
    )
    coroutine.yield()
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
            --         logError(msg)
            --         return
            --     end
            -- end)

            local flag, msg = coroutine.resume(waitCo)
            if not flag then
                msg = debug.traceback(waitCo, msg)
                --error(msg)
                logError(msg)
                return
            end
        end
    )

    coroutine.yield()
end
--------------------------------------
--设置当前房间所使用的风圈
--------------------------------------
function RoomView:setRoundMask(index)
    -- logger.debug("llwant , set round mask = " .. index)
    -- local curRoundMask = self.roundMarks[index]
    -- curRoundMask.transform:SetActive(true)
    -- self.curRoundMask = curRoundMask
    -- self:clearWaitingPlayer()
    -- --设置风圈和被当做花牌的风牌
    -- self.wind:SetActive(true)
    -- tileMounter:mountTileImage(self.windTile, self.room.windFlowerID)
    --self.playerViews[index]:setHeadEffectBox()
end
--------------------------------------
--设置当前房间所等待的操作玩家
--------------------------------------
function RoomView:setWaitingPlayer(player)
    --TODO:假设客户端只允许一个等待标志
    --因此设置一个等待时，先把其他的清理掉
    --self.room:startDiscardCountdown(31)
    self:clearWaitingPlayer()
    local viewChairID = player.playerView.viewChairID

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
--隐藏出牌提示箭头
--------------------------------------
function RoomView:setArrowHide()
    if self.arrowObj then
        self.arrowObj:Hide()
    end
end
--------------------------------------
--显示出牌提示箭头
--------------------------------------
function RoomView:setArrowByParent(parentObj)
    if self.arrowObj then
        self.arrowObj:SetParent(parentObj, false)
        --self.arrowObj.localPosition = Vector3(0, 0, 0)
        self.arrowObj.localPosition = Vector3(0, 40, 0)
        -- 这里不需要设置显不显示，因为会在SetOneOutCardShowByID中调用SetOutCardAni时让它显示出来的
        self.arrowObj:Show()

    -- 这里主要用来判断自摸的时候，隐藏上一家的打牌的箭头，如果是打牌出去，会在之后的代码中被显示出来。
    --self.arrowObj:Hide()
    end
end
function RoomView:destroyRoomView()
    --由于是切换回大厅时，是调用ViewManager.Replace("HallView")
    --ViewManager会destroy掉roomView的unity节点，因此这里不需要做什么
    if self.unityViewNode ~= nil then
        self.unityViewNode = nil
    end
end

--------------------------------------
--初始化房间号
--------------------------------------
function RoomView:initRoomNumber()
    self.roomInfoNode = self.unityViewNode.transform:Find("RoomInfo")
    self.roomNumberObject = self.unityViewNode.transform:Find("RoomInfo/RoomIDText")
    self.tipNode = self.roomInfoNode:Find("TipNode")
    self.finger = self.tipNode:Find("Finger")
    local isCopyRoomNum = Util.GetFromPlayerPrefs("isCopyRoomNum")
    if isCopyRoomNum == "1" then --复制过房号 则隐藏
        self.tipNode:SetActive(false)
    else
        self.tipNode:SetActive(true)
        local function fingerMove(posY)
            self.fingerMoveAction =
                self.unityViewNode:RunAction(
                self.finger,
                {
                    "localMoveBy",
                    0,
                    posY,
                    0.5,
                    onEnd = function()
                        fingerMove(-posY)
                    end
                }
            )
        end
        fingerMove(20)
    end
    self.roomNumber = self.unityViewNode:SubGet("RoomInfo/RoomIDText", "Text")
    self.roundInfo = self.unityViewNode:SubGet("RoomInfo/RoundInfo", "Text")

    self.roomNumberObject:SetActive(false)
    self.roundInfo:SetActive(false)
    self.unityViewNode:AddClick(
        self.roomInfoNode,
        function()
            if self.room.roomNumber == nil then
                return
            end
            self.tipNode:SetActive(false)
            local content = "大丰关张:房号【" .. self.room.roomNumber .. "】, " .. self:getInvitationDescription()
            Util.CopyClipboard(content)
            dfCompatibleAPI:showTip("复制房间信息成功，你可前往其他地方粘贴发送给好友！")
            Util.SaveToPlayerPrefs("isCopyRoomNum", "1")
            self.unityViewNode:StopAction(self.fingerMoveAction)
            self.finger:Hide()
        end
    )
end

function RoomView:initRoomTip()
    self.scrollTip = self.unityViewNode:FindChild("ExtendFuc/ScrollTip")
    -- ios提审
    if configModule:IsIosAudit() then
        return
    end

    self.scrollTip:SetActive(true)

    self.scrollTipText = self.scrollTip:Find("Tip")
    local tips = clone(dfConfig.RoomTips)
    local function showTip(time1, time2)
        if self.unityViewNode then
            self.unityViewNode:RunAction(
                self.scrollTipText,
                {
                    "fadeTo",
                    0,
                    time1,
                    function(...)
                        math.newrandomseed()
                        local curTipIndex = math.random(1, #tips)
                        self.scrollTipText.text = tips[curTipIndex]
                        table.remove(tips, curTipIndex)
                        if #tips <= 0 then
                            tips = clone(dfConfig.RoomTips)
                        end
                        self.unityViewNode:RunAction(self.scrollTipText, {"fadeTo", 255, time2})
                    end
                }
            )
        end
    end
    showTip(0, 2)
    self.unityViewNode:StartTimer(
        "SHowTips",
        5,
        function(...)
            showTip(1, 1)
        end,
        -1
    )

    self.ruleTipNode = self.unityViewNode:FindChild("ExtendFuc/TipNode")
    self.ruleFinger = self.ruleTipNode:Find("Finger")
    local isOpenRuleMsgBox = Util.GetFromPlayerPrefs("isOpenRuleMsgBox")
    if isOpenRuleMsgBox == "1" then --复制过房号 则隐藏
        self.ruleTipNode:SetActive(false)
    else
        self.ruleTipNode:SetActive(true)
        local function fingerMove(posY)
            self.fingerMoveAction1 =
                self.unityViewNode:RunAction(
                self.ruleFinger,
                {
                    "localMoveBy",
                    0,
                    posY,
                    0.5,
                    onEnd = function()
                        fingerMove(-posY)
                    end
                }
            )
        end
        fingerMove(20)
    end
end

--------------------------------------
--显示房间号
--------------------------------------
function RoomView:showRoomNumber()
    if self.roomNumber == nil then
        return
    end

    local obj = self.unityViewNode.transform:Find("RuleTop")
    local room = self.room
    if room.roomNumber ~= nil then
        -- obj:SetActive(true)
        self.roomNumber.text = string.format("房号:<color=#e9bf89>%s</color>", room.roomNumber)
        self.roomNumberObject:SetActive(true)
    end
    self.roundInfo:SetActive(true)
    local roundstr = "局数:<color=#e9bf89>%s/%s</color>"
    self.roundInfo.text =
        string.format(roundstr, tostring(self.room.handStartted) or "0", tostring((self.room.handNum)))
    if self.room.handStartted and self.room.handStartted > 0 then
        self.returnHallBtn:Hide()
    end
end

--初始化时间 wifi信号 电量
--------------------------------------
function RoomView:initPhoneInfo()
    -- iOS提审
    if configModule:IsIosAudit() then
        return
    end

    local timeObj = self.unityViewNode.transform:Find("ExtendFuc/Time")
    local pingObj = self.unityViewNode.transform:Find("ExtendFuc/Ping")
    local wifiObj = self.unityViewNode.transform:Find("ExtendFuc/Wifi")
    local cmcObj = self.unityViewNode.transform:Find("ExtendFuc/CMC")
    local powerObj = self.unityViewNode.transform:Find("ExtendFuc/Power")
    timeObj:SetActive(true)
    pingObj:SetActive(true)
    wifiObj:SetActive(true)
    cmcObj:SetActive(false)
    powerObj:SetActive(true)

    self.time = self.unityViewNode:SubGet("ExtendFuc/Time", "Text")
    self.ping = self.unityViewNode:SubGet("ExtendFuc/Ping", "Text")
    self.wifi = {}
    for i = 1, 2 do
        self.wifi[i] = self.unityViewNode.transform:Find("ExtendFuc/Wifi/Wifi" .. i)
    end
    self.cmc = {}
    for i = 1, 2 do
        self.cmc[i] = self.unityViewNode.transform:Find("ExtendFuc/CMC/CMC" .. i)
    end
    self.power = {}
    for i = 1, 3 do
        self.power[i] = self.unityViewNode.transform:Find("ExtendFuc/Power/Power" .. i)
    end
    local function updatePhoneInfo(...)
        local delay = self:getNetDelay()
        self.time.text = os.date("%H:%M", os.time())
        local battery = Util.GetBattery()
        local netAvailable = Util.NetAvailable
        local isWifi = Util.IsWifi
        if battery >= 90 then
            self.power[1]:SetActive(true)
            self.power[2]:SetActive(false)
            self.power[3]:SetActive(false)
        elseif battery >= 30 and battery < 90 then
            self.power[2]:SetActive(true)
            self.power[1]:SetActive(false)
            self.power[3]:SetActive(false)
        else
            self.power[3]:SetActive(true)
            self.power[2]:SetActive(false)
            self.power[1]:SetActive(false)
        end

        if netAvailable then
            if isWifi then
                wifiObj:SetActive(true)
                cmcObj:SetActive(false)
                self.ping.text = delay .. "ms"
                if delay > 200 then
                    self.ping:SetActive(true)
                    self.wifi[1]:SetActive(false)
                    self.wifi[2]:SetActive(true)
                else
                    self.ping:SetActive(false)
                    self.wifi[1]:SetActive(true)
                    self.wifi[2]:SetActive(false)
                end
            else
                wifiObj:SetActive(false)
                cmcObj:SetActive(true)
                self.ping.text = delay .. "ms"
                if delay > 200 then
                    self.ping:SetActive(true)
                    self.cmc[1]:SetActive(false)
                    self.cmc[2]:SetActive(true)
                else
                    self.ping:SetActive(false)
                    self.cmc[1]:SetActive(true)
                    self.cmc[2]:SetActive(false)
                end
            end
        else
            logger.debug("net is not Available！！")
        end
    end
    updatePhoneInfo()
    self.unityViewNode:StartTimer(
        "Clock",
        10,
        function(...)
            updatePhoneInfo()
        end,
        -1
    )
end

--------------------------------------
--解散房间按钮点击事件
--------------------------------------
function RoomView:onDissolveClick()
    msg = "确实要申请解散房间吗？"
    local roomView = self

    dfCompatibleAPI:showMessageBox(
        msg,
        function()
            local room = roomView.room
            --先向服务器发送解散房间请求
            room:onDissolveClicked()
            if inGameChatPanel then
                inGameChatPanel:CleanupChatMsg()
            end
        end,
        function()
            --nothing to do
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
    for i, v in ipairs(self.playerViews) do
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

    for k, v in pairs(self.timer) do
        if v then
            StopTimer(v)
        end
    end
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
    self.voiceButton = self.unityViewNode.transform:Find("ExtendFuc/RightBtns/chat_audio_btn")
    local w = self.voiceButton.width
    local h = self.voiceButton.height
    local scrPos =
        Util.GetUICamera():GetComponent(typeof(UnityEngine.Camera)):WorldToScreenPoint(self.voiceButton.position)
    local rect = UnityEngine.Rect(scrPos.x - w / 2, scrPos.y - h / 2, w, h)
    local init = function()
        if not self.voiceLayer then
            self.voiceLayer = self:createVoiceLayer()
            self.voiceLayer:SetVoiceButtonRect(rect)
            self.voiceLayer:ResetMode()
        end
    end
    init() -- 初始化
    self.voiceButton.onDown = function()
        self.voiceLayer:OnVoiceButtonDown(self.room.user.userID)
    end
    self.voiceButton.onUp = function()
        self.voiceLayer:OnVoiceButtonUp(self.room.user.userID)
    end
    self.voiceButton.onDrag = function(sender, eventData)
        self.voiceLayer:OnVoiceButtonDrag(sender, eventData)
    end
    self.delayRunMap = {}
end

function RoomView:createVoiceLayer()
    local layer =
        viewModule:CreatePanel(
        {
            luaPath = "VoiceComponent.Script.VoiceLayer",
            resPath = "Component/VoiceComponent/Bundle/prefab/VoiceLayer.prefab",
            superClass = self.unityViewNode,
            parentNode = self.unityViewNode.transform
        }
    )
    local uiDepth = layer:GetComponent("UIDepth")
    if not uiDepth then
        uiDepth = layer:AddComponent(UIDepth)
    end
    uiDepth.canvasOrder = self.unityViewNode.order + 2
    return layer
end

----------------------------------------------------------
--初始化房间状态事件
----------------------------------------------------------
function RoomView:initRoomStatus()
    local roomView = self
    local room = self.room

    -- 房间正在等待玩家准备
    local onWait = function()
        roomView.wind:SetActive(false)
        --等待状态重置上手牌遗留
        roomView.room:resetForNewHand()
        --roomView.tilesInWall:SetActive(false)

        local config = self.room:getRoomConfig()
        if config ~= nil then
            logger.debug(" players:" .. room:playerCount() .. ", required:" .. config.playerNumAcquired)
            if room:playerCount() >= config.playerNumAcquired then
                roomView.invitButton:SetActive(false)
            else
                roomView.invitButton:SetActive(true)
                -- IOS 提审
                if configModule:IsIosAudit() then
                    roomView.invitButton:SetActive(false)
                end
            end
        end

        roomView:updateLeaveAndDisbandButtons()
    end

    --房间空闲，客户端永远看不到这个状态
    local onIdle = function()
    end

    -- 游戏开始了
    local onPlay = function()
        roomView.invitButton:SetActive(false)
        roomView.returnHallBtn:SetActive(false)
        --roomView.wind:SetActive(false) --发牌的时候，或者掉线恢复的时候会设置风圈因此此处不需要visible

        --if not room:isReplayMode() then
        --<color=#775D42FF>" .. formatStr .. "</color>
        local roundstr = "局数:<color=#e9bf89>%s/%s</color>"
        --roomView.tilesInWall:SetActive(true)
        roomView.tipNode:SetActive(false)
        roomView.ruleTipNode:SetActive(false)
        roomView.roundInfo.text =
            string.format(roundstr, tostring(self.room.handStartted), tostring((self.room.handNum)))
        -- else
        --     roomView.curRound:SetActive(false)
        --     roomView.totalRound:SetActive(false)
        -- end

        roomView:updateLeaveAndDisbandButtons()
        self.scrollTip:Hide()
        self.unityViewNode:StopTimer("SHowTips")
        self.unityViewNode:StopAction(self.fingerMoveAction)
        self.unityViewNode:StopAction(self.fingerMoveAction1)
        self:hideNoFriendTips()
    end

    --房间已经被删除，客户端永远看不到这个状态
    local onDelete = function()
    end

    local status = {}
    status[pkproto2.SRoomIdle] = onIdle
    status[pkproto2.SRoomWaiting] = onWait
    status[pkproto2.SRoomPlaying] = onPlay
    status[pkproto2.SRoomDeleted] = onDelete
    self.statusHandlers = status
end

function RoomView:hideNoFriendTips()
    for i, tip in ipairs(self.noFriendTips) do
        tip:Hide()
    end
end

----------------------------------------------------------
--初始化房间玩家自己与其他玩家的关系
----------------------------------------------------------
function RoomView:initPlayersRelation()
    if not configModule:IsShowNotFriendTip() then
        return
    end
    self:hideNoFriendTips()
    local viewChairIDs = {}
    local myGroupIds = self.room.myPlayer.groupIds or {}
    for userId, player in pairs(self.room.players) do
        if userId ~= self.room.myPlayer.userID then
            local isFriend = false
            local groupIds = player.groupIds or {}
            for i, myGroupId in ipairs(myGroupIds) do
                for i, groupId in ipairs(groupIds) do
                    if tonumber(myGroupId) and tonumber(groupId) and myGroupId == groupId then
                        isFriend = true
                        break
                    end
                end
                if isFriend then
                    break
                end
            end
            if not isFriend then
                local viewChairID = player.playerView.viewChairID
                table.insert(viewChairIDs, viewChairID)
            end
        end
    end
    for i, viewChairID in ipairs(viewChairIDs) do
        self.noFriendTips[viewChairID - 1]:SetActive(g_dataModule:GetFunctionSwitchInfo(function_switch_pb.FSPaiYouQun))
    end
end
----------------------------------------------------------
--根据游戏状态控制两个按钮的可见性
----------------------------------------------------------
function RoomView:updateLeaveAndDisbandButtons()
    local room = self.room

    --logger.debug("room:me().userID == "..room:me().userID)

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
    self.addedRule:SetActive(false)

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
    local isDoubleScoreWhenContinuousBanker =
        config.doubleScoreWhenContinuousBanker ~= nil and config.doubleScoreWhenContinuousBanker

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
        self.addedRule:SetActive(true)
    else
        self.addedRule:SetActive(false)
    end
end

-- --------------------------------------------------------
-- 邀请好友进入游戏
-- --------------------------------------------------------
function RoomView:getInvitationDescription(isLoadDouble)
    local rule = ""
    local config = self.room:getRoomConfig()
    local players = self.room.players
    local playerNumber = 0
    for _, p in pairs(players) do
        playerNumber = playerNumber + 1
    end
    local playerNumAcquired = ""
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

        logger.debug("llwant , RoomView:getInvitationDescription rule : " .. rule)
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
----------------------------------------------------------
-- 隐藏空椅子
-- 如果是两个玩家，则隐藏2、4号椅子
-- 如果是三个玩家，则隐藏4号椅子
-- 如果是四个玩家，则不隐藏椅子
----------------------------------------------------------
function RoomView:hideEmptyChair(myChairId)
    --logError("hideEmptyChair, myChairId: "..myChairId)
    local roomInfo = self.room.roomInfo

    if roomInfo == nil or roomInfo.config == nil then
        logError("initChair, roomInfo == nil or roomInfo.config == nil ")
        --roomInfo 为空的时候。说明是回播的时候进来的，这时候不需要显示椅子
        self.unityViewNode.transform:Find("PlayInfoGroup/1empty"):SetActive(false)
        self.unityViewNode.transform:Find("PlayInfoGroup/2empty"):SetActive(false)
        self.unityViewNode.transform:Find("PlayInfoGroup/3empty"):SetActive(false)
        -- self.unityViewNode.transform:Find("PlayInfoGroup/4empty"):SetActive(false)
        return
    end

    local roomConfig = Json.decode(roomInfo.config)
    if roomConfig == nil then
        logError("initChair, roomConfig == nil  ")
        return
    end

    local playerNum = roomConfig.playerNumAcquired
    if playerNum == nil then
        logError("initChair, playerNum == nil  ")
        return
    end

    -- local myViewChairId = 1
    --(myChairId + 1 - myViewChairId) == ( chair2 - viewChairId2)
    local chair2 = 1
    local chair4 = 3
    --local viewChairId2 = chair2 -( myChairId)
    --local viewChairId4 = chair4 -( myChairId)

    --获得chairID相对于本玩家的偏移
    local viewChairId2 = (chair2 - myChairId + 4) % 4 + 1
    local viewChairId4 = (chair4 - myChairId + 4) % 4 + 1
    --logError("hideEmptyChair, viewChairId2: "..viewChairId2)
    --logError("hideEmptyChair, viewChairId4: "..viewChairId4)
    local chairView2 = self.unityViewNode.transform:Find("PlayInfoGroup/" .. viewChairId2 .. "empty")
    local chairView4 = self.unityViewNode.transform:Find("PlayInfoGroup/" .. viewChairId4 .. "empty")

    if playerNum == 2 then
        chairView2:SetActive(false)
        chairView4:SetActive(false)
    end

    if playerNum == 3 then
        chairView4:SetActive(false)
    end
end

----------------------------------------------------------
-- 玩家退出，恢复椅子
----------------------------------------------------------
function RoomView:restoreChair(viewChairId)
    local chairView = self.unityViewNode.transform:Find("PlayInfoGroup/" .. viewChairId .. "empty")
    chairView:SetActive(true)
end

--初始化房间皮肤
function RoomView:initRoomSkin(index)
    --设置默认的皮肤
    local skinIndex = index or 2
    if not index then
        if userDataModule.accountCfg.skinIndex == "1" then
            skinIndex = 1
        end
    end
    self.skinIndex = skinIndex
    self.skinManager:Replace(skinIndex)
end

function RoomView:registerBroadcast()
    dispatcher:register("BROADCAST_CHANNEL_10045", self, self.onBroadcast)
    dispatcher:register("ANTI_ADDICTION", self, self.AntiAddiction)
    dispatcher:register("FunctionSwitch", self, self.FunctionSwitch)
end

function RoomView:unregisterBroadcast()
    dispatcher:unregister("BROADCAST_CHANNEL_10045", self, self.onBroadcast)
    dispatcher:unregister("ANTI_ADDICTION", self, self.AntiAddiction)
    dispatcher:unregister("FunctionSwitch", self, self.FunctionSwitch)
end

function RoomView:AntiAddiction(fillIn, onlineTime)
    logger.debug("room receive AntiAddiction---------------------------------------------------------")
    g_dataModule:SetAntiAddiction(nil)
    if onlineTime == 1 or onlineTime == 2 then
        g_commonModule:ShowTip(string.format("您累计在线时间已满%s小时", onlineTime), 3)
    elseif onlineTime > 2 then
        g_dataModule:SetAntiAddiction({fillIn = fillIn, onlineTime = onlineTime})
    end
end

function RoomView:onBroadcast(message)
    logger.debug("onBroadcast: " .. message.content)
    g_commonModule:ShowBroadcast(message.content, message.speed)
end

-------------------------------------------------
---- 更新道具配置
------------------------------------------------
function RoomView:refreshProps()
    if not self.room then
        return
    end
    if not self.otherUserInfoObj or not self.unityViewNode.donateBtns then
        return
    end
    for i, donateBtn in ipairs(self.unityViewNode.donateBtns) do
        local propIcon = donateBtn:Find("ImageConf")
        local charmText = donateBtn:Find("TextXin")
        local diamondText = donateBtn:Find("TextZuan")
        local propNum = donateBtn:Find("ItemNum")
        local prop = self.room:getPropCfg(i)
        if prop ~= nil then
            charmText.text = prop["charm"]
            diamondText.text = prop["diamond"]

            local propID = prop["propID"]
            local num = g_dataModule:GetPackagePropNum(propID)
            logger.debug("num" .. tostring(num) .. ", propID:" .. tostring(propID))
            if num and num ~= 0 then
                propNum:SetActive(true)
                local propNumText = propNum:Find("Text")
                propNumText.text = "免费" .. tostring(num) .. "次"
            end
            propIcon:SetImage("Component/CommonComponent/Bundle/image/prop/" .. propID .. ".png")
        end
    end
end

function RoomView:FunctionSwitch()
    local show = g_dataModule:GetFunctionSwitchInfo(function_switch_pb.FSDuanWei)
    self.unityViewNode.transform:Find("UserInfo/MyInfoBg/Info/SegmentLogo"):SetActive(show)
    self.unityViewNode.transform:Find("UserInfo/MyInfoBg/Info/SegmentLogoText"):SetActive(show)
    self.unityViewNode.transform:Find("UserInfo/OtherInfoBg/Info/SegmentLogo"):SetActive(show)
    self.unityViewNode.transform:Find("UserInfo/OtherInfoBg/Info/SegmentLogoText"):SetActive(show)
end

return RoomView
