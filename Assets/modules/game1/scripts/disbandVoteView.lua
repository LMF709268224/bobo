local DisbandVoteView = {}

local mt = {__index = DisbandVoteView}

local logger = require "lobby/lcore/logger"
local prompt = require "lobby/lcore/prompt"
local proto = require "scripts/proto/proto"
local fairy = require "lobby/lcore/fairygui"

function DisbandVoteView.new(room, viewObj)
    local disbandVoteView = {}
    setmetatable(disbandVoteView, mt)

    disbandVoteView.room = room

    --房间解散状态是以messagebox来显示
    --disbandVoteView.viewObj = ViewManager.OpenMessageBox(prefabName)
    --disbandVoteView.viewObj = room:openMessageBoxFromDaFeng(prefabName,10) --结算界面的order in layer太大，解散界面得填10才能不被挡住
    disbandVoteView.viewObj = viewObj

    disbandVoteView.refuseBtn = viewObj:GetChild("unagreeBtn")
    disbandVoteView.agreeBtn = viewObj:GetChild("agreeBtn")

    disbandVoteView.refuseBtn.onClick:Set(
        function()
            disbandVoteView:onRefuseBtnClicked()
        end
    )

    disbandVoteView.agreeBtn.onClick:Set(
        function()
            disbandVoteView:onAgreeBtnClicked()
        end
    )

    disbandVoteView.title = viewObj:GetChild("name")

    disbandVoteView.myCountDown = viewObj:GetChild("n9")
    disbandVoteView.myCountDownTxt = viewObj:GetChild("time")
    -- disbandVoteView.otherCountDown = viewObj.transform:GetChild("otherTxt")
    -- disbandVoteView.otherCountDownTxt = viewObj:SubGet("otherTxt/lefttime", "Text")

    --disbandVoteView.myCountDown.visible = false
    --disbandVoteView.otherCountDown.visible = false

    disbandVoteView.playerList = {}
    --以下代码从DissolveVoteView2.lua中拷贝过来
    for i = 1, 3 do
        local _playeri = viewObj:GetChild("player" .. i)
        local _NameText = _playeri:GetChild("name")
        local _SpState_Refuse = _playeri:GetChild("unagree")
        local _SpState_Agree = _playeri:GetChild("agree")
        local _SpState_Thinking = _playeri:GetChild("wait")

        _SpState_Refuse.visible = false
        _SpState_Agree.visible = false
        _SpState_Thinking.visible = false
        _playeri.visible = false

        disbandVoteView.playerList[i] = {
            root = _playeri,
            nameText = _NameText,
            spState_Refuse = _SpState_Refuse,
            spState_Agree = _SpState_Agree,
            spState_Thinking = _SpState_Thinking
        }
    end

    -- local playerNumber = 0
    -- local roomConfig = room:getRoomConfig()
    -- if roomConfig ~= nil then
    --     playerNumber = roomConfig.playerNumAcquired
    -- end

    -- 如果只有两个用户，则2与3调换位置
    -- if playerNumber == 2 then
    --     local player2 = disbandVoteView.playerList[2]
    --     disbandVoteView.playerList[2] = disbandVoteView.playerList[3]
    --     disbandVoteView.playerList[3] = player2

    --     local originPos1 = disbandVoteView.playerList[1].root.transform.localPosition
    --     local originPos2 = disbandVoteView.playerList[3].root.transform.localPosition
    --     -- local width = disbandVoteView.playerList[3].root.transform.width

    --     disbandVoteView.playerList[1].root.transform.localPosition = Vector3(originPos1.x, originPos1.y - 60, 0)
    --     disbandVoteView.playerList[3].root.transform.localPosition = Vector3(originPos2.x, originPos2.y - 60, 0)
    -- end

    fairy.GRoot.inst:AddChild(viewObj)

    return disbandVoteView
end

function DisbandVoteView:getPlayerNick(chairID)
    local player = self.room:getPlayerByChairID(chairID)
    local nick = player.nick
    if nick == "" then
        nick = player.userID
    end
    -- nick = g_ModuleMgr:GetModule(ModuleName.TOOLLIB_MODULE):FormotGameNickName(nick, 6)
    return nick
end

function DisbandVoteView:updateTexts(msgDisbandNotify)
    local nick = self:getPlayerNick(msgDisbandNotify.applicant)
    local title = nick --"玩家 <color=#527983>" .. nick .. "</color> 申请解散房间"
    -- if msgDisbandNotify.disbandState == pkproto2.Waiting then
    --     title = title..":正等待回复"
    -- elseif msgDisbandNotify.disbandState == pkproto2.DoneWithWaitReplyTimeout then
    --     title = title..":失败，超时"
    -- elseif msgDisbandNotify.disbandState == pkproto2.DoneWithRoomServerNotResponse then
    --     title = title..":失败，响应超时"
    -- elseif msgDisbandNotify.disbandState == pkproto2.DoneWithOtherReject then
    --     title = title..":失败，玩家拒绝"
    -- elseif msgDisbandNotify.disbandState == pkproto2.Done then
    --     title = title..":解散成功"
    -- end

    self.title.text = title

    --先全部隐藏
    for i = 1, 3 do
        local p = self.playerList[i]
        p.root.visible = false
        p.spState_Agree.visible = false
        p.spState_Thinking.visible = false
        p.spState_Refuse.visible = false
    end

    -- 显示谁解散房间
    if self.room:getPlayerByChairID(msgDisbandNotify.applicant) ~= nil then
        local p = self.playerList[msgDisbandNotify.applicant + 1]
        nick = self:getPlayerNick(msgDisbandNotify.applicant)
        p.nameText.text = nick
        logger.debug(" player ", nick, " applicate")
        p.spState_Agree.visible = true
        p.root.visible = true
    -- index = index + 1
    end

    -- local index = 1
    --等待中的玩家列表
    if msgDisbandNotify.waits ~= nil then
        logger.debug(" msgDisbandNotify.waits length:", #msgDisbandNotify.waits)
        for _, chairID in ipairs(msgDisbandNotify.waits) do
            if self.room:getPlayerByChairID(chairID) ~= nil then
                logger.debug(" msgDisbandNotify.waits chairID:", chairID)
                local p = self.playerList[chairID + 1]
                nick = self:getPlayerNick(chairID)
                p.nameText.text = nick
                logger.debug(" player ", nick, " thinking")
                p.spState_Thinking.visible = true
                p.root.visible = true
            -- index = index + 1
            end
        end
    end

    --同意的玩家列表
    if msgDisbandNotify.agrees ~= nil then
        logger.debug(" msgDisbandNotify.agrees length:", #msgDisbandNotify.agrees)
        for _, chairID in ipairs(msgDisbandNotify.agrees) do
            if self.room:getPlayerByChairID(chairID) ~= nil then
                local p = self.playerList[chairID + 1]
                nick = self:getPlayerNick(chairID)
                p.nameText.text = nick
                logger.debug(" player ", nick, " agree")
                p.spState_Agree.visible = true
                p.root.visible = true
            -- index = index + 1
            end
        end
    end

    --拒绝的玩家列表
    if msgDisbandNotify.rejects ~= nil then
        logger.debug(" msgDisbandNotify.rejectslength:", #msgDisbandNotify.rejects)
        local isShowTip = true
        for _, chairID in ipairs(msgDisbandNotify.rejects) do
            if self.room:getPlayerByChairID(chairID) ~= nil then
                local p = self.playerList[chairID + 1]
                nick = self:getPlayerNick(chairID)
                p.nameText.text = nick
                logger.debug(" player ", nick, " refused")
                p.spState_Refuse.visible = true
                p.root.visible = true
                -- index = index + 1

                if isShowTip then
                    local str = "玩家 " .. nick .. " 不同意解散，解散不成功!"
                    prompt.showPrompt(str)
                    isShowTip = false
                end
            end
        end
    end
end

function DisbandVoteView:updateView(msgDisbandNotify)
    --logger.debug(" DisbandVoteView update view")
    --先更新所有文字信息，例如谁同意，谁拒绝之类
    self:updateTexts(msgDisbandNotify)

    local disbandStateEnum = proto.pokerface.DisbandState
    local isReject = msgDisbandNotify.disbandState == disbandStateEnum.DoneWithOtherReject
    local isTimeout = msgDisbandNotify.disbandState == disbandStateEnum.DoneWithWaitReplyTimeout
    local isNotResponse = msgDisbandNotify.disbandState == disbandStateEnum.DoneWithRoomServerNotResponse
    if isReject or isTimeout or isNotResponse then
        self.myCountDown.visible = false
        --self.otherCountDown.visible = false

        self.refuseBtn.visible = false
        self.agreeBtn.visible = true
        self.isDisbandDone = true

        local disbandVoteView = self
        disbandVoteView:onAgreeBtnClicked()
    elseif msgDisbandNotify.disbandState == disbandStateEnum.Done then
        self.isDisbandDone = true
        self:onAgreeBtnClicked()
    elseif msgDisbandNotify.disbandState == disbandStateEnum.Waiting then
        --如果等待列表中有自己，则显示选择按钮，以便玩家做出选择
        if msgDisbandNotify.countdown then
            self.viewObj:StopTimer("disbandCountDown")
            self.leftTime = msgDisbandNotify.countdown --倒计时时间，秒为单位

            local disbandVoteView = self

            local found = false
            local me = self.room.myPlayer

            for _, chairID in ipairs(msgDisbandNotify.waits) do
                if chairID == me.chairID then
                    found = true
                end
            end

            if not found then
                if #msgDisbandNotify.waits > 0 then
                    disbandVoteView.myCountDownTxt.text = disbandVoteView.leftTime .. "秒"
                    if disbandVoteView.leftTime <= 0 then
                        disbandVoteView.viewObj:StopTimer("disbandCountDown")
                    end
                    self.myCountDown.visible = true
                    --为他人倒计时
                    self.viewObj:StartTimer(
                        "disbandCountDown",
                        1,
                        0,
                        function()
                            disbandVoteView.leftTime = disbandVoteView.leftTime - 1
                            disbandVoteView.myCountDownTxt.text = disbandVoteView.leftTime .. "秒"
                            if disbandVoteView.leftTime <= 0 then
                                disbandVoteView.viewObj:StopTimer("disbandCountDown")
                            end
                        end,
                        disbandVoteView.leftTime
                    )
                end
                --self.otherCountDown.visible = false
                self:showButtons(false)
                return
            else
                self.myCountDown.visible = false
                --self.otherCountDown.visible = true
                self:showButtons(true)
            end

            --disbandVoteView.otherCountDownTxt.text = disbandVoteView.leftTime .. "秒"
            --为自己倒计时
            self.viewObj:StartTimer(
                "disbandCountDown",
                1,
                0,
                function()
                    disbandVoteView.leftTime = disbandVoteView.leftTime - 1
                    --disbandVoteView.otherCountDownTxt.text = disbandVoteView.leftTime .. "秒"
                    if disbandVoteView.leftTime <= 0 then
                        disbandVoteView.viewObj:StopTimer("disbandCountDown")
                        disbandVoteView:onAgreeBtnClicked()
                    end
                end,
                disbandVoteView.leftTime
            )
        end
    end
end

function DisbandVoteView:showButtons(show)
    if show then
        self.refuseBtn.visible = show
        self.agreeBtn.visible = show
    else
        self.refuseBtn.enabled = false
        self.agreeBtn.enabled = false
    end
end

function DisbandVoteView:onRefuseBtnClicked()
    --Network.SendAgreeDismissTableReq(2)
    --logger.debug(" you choose to refuse disband")
    --拒绝请求,因此隐藏所有按钮
    self:showButtons(false)

    --发送回复给服务器
    self.room:sendDisbandAgree(false)

    self.viewObj:StopTimer("disbandCountDown")

    self.hasReply = true
end

function DisbandVoteView:onAgreeBtnClicked()
    --Network.SendAgreeDismissTableReq(1)
    --logger.debug(" agree btn clicked")
    self.viewObj:StopTimer("disbandCountDown")

    if self.isDisbandDone then
        --已经完成了解散请求
        self:destroy()
    else
        logger.debug(" you choose to agree disband")
        --同意请求,因此隐藏所有按钮
        self:showButtons(false)

        --发送回复给服务器
        self.room:sendDisbandAgree(true)
        self.hasReply = true
    end
end

function DisbandVoteView:destroy()
    --重置room中的开关变量
    self.room.disbandVoteView = nil
    self.room.disbandLocked = nil
    self.msgDisbandNotify = nil

    self.viewObj:Dispose()
end

return DisbandVoteView
