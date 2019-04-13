local DisbandVoteView = {}
DisbandVoteView.VERSION = "1.0"

local mt = {__index = DisbandVoteView}

function DisbandVoteView.new(room, viewObj)
    local disbandVoteView = {}
    setmetatable(disbandVoteView, mt)

    disbandVoteView.room = room

    --房间解散状态是以messagebox来显示
    --disbandVoteView.unityViewNode = ViewManager.OpenMessageBox(prefabName)
    --disbandVoteView.unityViewNode = room:openMessageBoxFromDaFeng(prefabName,10) --结算界面的order in layer太大，解散界面得填10才能不被挡住
    disbandVoteView.unityViewNode = viewObj
    local unityViewNode = disbandVoteView.unityViewNode

    disbandVoteView.refuseBtn = unityViewNode.transform:Find("btns/RefuseBtn")
    disbandVoteView.agreeBtn = unityViewNode.transform:Find("btns/AgreeBtn")

    disbandVoteView.refuseBtnText = unityViewNode:SubGet("btns/RefuseBtn/Text", "Text")
    disbandVoteView.agreeBtnText = unityViewNode:SubGet("btns/AgreeBtn/Text", "Text")

    unityViewNode:AddClick(
        disbandVoteView.refuseBtn,
        function()
            disbandVoteView:onRefuseBtnClicked()
        end
    )
    unityViewNode:AddClick(
        disbandVoteView.agreeBtn,
        function()
            disbandVoteView:onAgreeBtnClicked()
        end
    )

    disbandVoteView.title = unityViewNode:SubGet("titleText", "Text")

    disbandVoteView.myCountDown = unityViewNode.transform:Find("mineTxt")
    disbandVoteView.myCountDownTxt = unityViewNode:SubGet("mineTxt/lefttime", "Text")
    disbandVoteView.otherCountDown = unityViewNode.transform:Find("otherTxt")
    disbandVoteView.otherCountDownTxt = unityViewNode:SubGet("otherTxt/lefttime", "Text")

    disbandVoteView.myCountDown:SetActive(false)
    disbandVoteView.otherCountDown:SetActive(false)

    disbandVoteView.playerList = {}
    --以下代码从DissolveVoteView2.lua中拷贝过来
    for i = 1, 4 do
        local _playeri = unityViewNode.transform:Find("MsgPlayer/Grid/player" .. i)
        local _NameText = unityViewNode:SubGet("MsgPlayer/Grid/player" .. i .. "/Name", "Text")
        local _SpState_Refuse = unityViewNode.transform:Find("MsgPlayer/Grid/player" .. i .. "/ImageRefuse")
        local _SpState_Agree = unityViewNode.transform:Find("MsgPlayer/Grid/player" .. i .. "/ImageAgree")
        local _SpState_Thinking = unityViewNode.transform:Find("MsgPlayer/Grid/player" .. i .. "/ImageThink")

        _SpState_Refuse:SetActive(false)
        _SpState_Agree:SetActive(false)
        _SpState_Thinking:SetActive(false)
        _playeri:SetActive(false)

        disbandVoteView.playerList[i] = {
            root = _playeri,
            nameText = _NameText,
            spState_Refuse = _SpState_Refuse,
            spState_Agree = _SpState_Agree,
            spState_Thinking = _SpState_Thinking
        }
    end

    local playerNumber = 0
    local roomConfig = room:getRoomConfig()
    if roomConfig ~= nil then
        playerNumber = roomConfig.playerNumAcquired
    end

    -- 如果只有两个用户，则2与3调换位置
    if playerNumber == 2 then
        local player2 = disbandVoteView.playerList[2]
        disbandVoteView.playerList[2] = disbandVoteView.playerList[3]
        disbandVoteView.playerList[3] = player2

        local originPos1 = disbandVoteView.playerList[1].root.transform.localPosition
        local originPos2 = disbandVoteView.playerList[3].root.transform.localPosition
        -- local width = disbandVoteView.playerList[3].root.transform.width

        disbandVoteView.playerList[1].root.transform.localPosition = Vector3(originPos1.x, originPos1.y - 60, 0)
        disbandVoteView.playerList[3].root.transform.localPosition = Vector3(originPos2.x, originPos2.y - 60, 0)
    end

    return disbandVoteView
end

function DisbandVoteView:getPlayerNick(chairID)
    local player = self.room:getPlayerByChairID(chairID)
    local nick = player.nick
    if nick == "" then
        nick = player.userID
    end
    nick = g_ModuleMgr:GetModule(ModuleName.TOOLLIB_MODULE):FormotGameNickName(nick, 6)
    return nick
end

function DisbandVoteView:updateTexts(msgDisbandNotify)
    local nick = self:getPlayerNick(msgDisbandNotify.applicant)
    local title = "玩家 <color=#527983>" .. nick .. "</color> 申请解散房间"
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
    for i = 1, 4 do
        local p = self.playerList[i]
        p.root:SetActive(false)
        p.spState_Agree:SetActive(false)
        p.spState_Thinking:SetActive(false)
        p.spState_Refuse:SetActive(false)
    end

    -- 显示谁解散房间
    if self.room:getPlayerByChairID(msgDisbandNotify.applicant) ~= nil then
        local p = self.playerList[msgDisbandNotify.applicant + 1]
        nick = self:getPlayerNick(msgDisbandNotify.applicant)
        p.nameText.text = "玩家(" .. nick .. ")"
        logger.debug(" player " .. nick .. "refused")
        p.spState_Agree:SetActive(true)
        p.root:SetActive(true)
    -- index = index + 1
    end

    -- local index = 1
    --等待中的玩家列表
    if msgDisbandNotify.waits ~= nil then
        logger.debug(" msgDisbandNotify.waits length:" .. #msgDisbandNotify.waits)
        for _, chairID in ipairs(msgDisbandNotify.waits) do
            if self.room:getPlayerByChairID(chairID) ~= nil then
                logger.debug(" msgDisbandNotify.waits chairID:" .. chairID)
                local p = self.playerList[chairID + 1]
                nick = self:getPlayerNick(chairID)
                p.nameText.text = "玩家(" .. nick .. ")"
                logger.debug(" player " .. nick .. "thinking")
                p.spState_Thinking:SetActive(true)
                p.root:SetActive(true)
            -- index = index + 1
            end
        end
    end

    --同意的玩家列表
    if msgDisbandNotify.agrees ~= nil then
        logger.debug(" msgDisbandNotify.agrees length:" .. #msgDisbandNotify.agrees)
        for _, chairID in ipairs(msgDisbandNotify.agrees) do
            if self.room:getPlayerByChairID(chairID) ~= nil then
                local p = self.playerList[chairID + 1]
                nick = self:getPlayerNick(chairID)
                p.nameText.text = "玩家(" .. nick .. ")"
                logger.debug(" player " .. nick .. "agree")
                p.spState_Agree:SetActive(true)
                p.root:SetActive(true)
            -- index = index + 1
            end
        end
    end

    --拒绝的玩家列表
    if msgDisbandNotify.rejects ~= nil then
        logger.debug(" msgDisbandNotify.rejectslength:" .. #msgDisbandNotify.rejects)
        local isShowTip = true
        for i, chairID in ipairs(msgDisbandNotify.rejects) do
            if self.room:getPlayerByChairID(chairID) ~= nil then
                local p = self.playerList[chairID + 1]
                nick = self:getPlayerNick(chairID)
                p.nameText.text = "玩家(" .. nick .. ")"
                logger.debug(" player " .. nick .. "refused")
                p.spState_Refuse:SetActive(true)
                p.root:SetActive(true)
                -- index = index + 1

                if isShowTip then
                    local str = "玩家 " .. nick .. " 不同意解散，解散不成功!"
                    g_commonModule:ShowTip(str, 2)
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

    if
        msgDisbandNotify.disbandState == pkproto2.DoneWithOtherReject or msgDisbandNotify.disbandState == pkproto2.DoneWithWaitReplyTimeout or
            msgDisbandNotify.disbandState == pkproto2.DoneWithRoomServerNotResponse
     then
        self.myCountDown:SetActive(false)
        self.otherCountDown:SetActive(false)

        self.refuseBtn:SetActive(false)
        self.agreeBtn:SetActive(true)
        self.isDisbandDone = true

        local disbandVoteView = self
        disbandVoteView:onAgreeBtnClicked()
    elseif msgDisbandNotify.disbandState == mjproto2.Done then
        self.isDisbandDone = true
        self:onAgreeBtnClicked()
    elseif msgDisbandNotify.disbandState == pkproto2.Waiting then
        --如果等待列表中有自己，则显示选择按钮，以便玩家做出选择
        if msgDisbandNotify.countdown then
            self.unityViewNode:StopTimer("disbandCountDown")
            self.leftTime = msgDisbandNotify.countdown --倒计时时间，秒为单位

            local disbandVoteView = self

            local found = false
            local me = self.room:me()

            for _, chairID in ipairs(msgDisbandNotify.waits) do
                if chairID == me.chairID then
                    found = true
                end
            end

            if not found then
                if #msgDisbandNotify.waits > 0 then
                    disbandVoteView.myCountDownTxt.text = disbandVoteView.leftTime .. "秒"
                    if disbandVoteView.leftTime <= 0 then
                        disbandVoteView.unityViewNode:StopTimer("disbandCountDown")
                    end
                    self.myCountDown:SetActive(true)
                    --为他人倒计时
                    self.unityViewNode:StartTimer(
                        "disbandCountDown",
                        1,
                        function()
                            disbandVoteView.leftTime = disbandVoteView.leftTime - 1
                            disbandVoteView.myCountDownTxt.text = disbandVoteView.leftTime .. "秒"
                            if disbandVoteView.leftTime <= 0 then
                                disbandVoteView.unityViewNode:StopTimer("disbandCountDown")
                            end
                        end,
                        disbandVoteView.leftTime
                    )
                end
                self.otherCountDown:SetActive(false)
                self:showButtons(false)
                return
            else
                self.myCountDown:SetActive(false)
                self.otherCountDown:SetActive(true)
                self:showButtons(true)
            end
            logger.debug("1222222222222222222222222222")
            disbandVoteView.otherCountDownTxt.text = disbandVoteView.leftTime .. "秒"
            --为自己倒计时
            self.unityViewNode:StartTimer(
                "disbandCountDown",
                1,
                function()
                    disbandVoteView.leftTime = disbandVoteView.leftTime - 1
                    disbandVoteView.otherCountDownTxt.text = disbandVoteView.leftTime .. "秒"
                    if disbandVoteView.leftTime <= 0 then
                        disbandVoteView.unityViewNode:StopTimer("disbandCountDown")
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
        self.refuseBtn:SetActive(show)
        self.agreeBtn:SetActive(show)
    else
        self.refuseBtn.interactable = false
        self.agreeBtn.interactable = false
    end
end

function DisbandVoteView:onRefuseBtnClicked()
    --Network.SendAgreeDismissTableReq(2)
    --logger.debug(" you choose to refuse disband")
    --拒绝请求,因此隐藏所有按钮
    self:showButtons(false)

    --发送回复给服务器
    self.room:sendDisbandAgree(false)

    self.unityViewNode:StopTimer("disbandCountDown")

    self.hasReply = true
end

function DisbandVoteView:onAgreeBtnClicked()
    --Network.SendAgreeDismissTableReq(1)
    --logger.debug(" agree btn clicked")
    self.unityViewNode:StopTimer("disbandCountDown")

    if self.isDisbandDone then
        --已经完成了解散请求
        self:destroy()

        if self.waitCo ~= nil then
            --由于等待状态下cortouine挂起，因此需要resume
            local flag, msg = coroutine.resume(self.waitCo)
            if not flag then
                logError(msg)
                return
            end
        end
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

    self.unityViewNode:Destroy()
end

return DisbandVoteView
