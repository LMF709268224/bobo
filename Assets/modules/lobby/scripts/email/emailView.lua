--[[
    -- 邮件
]]
--luacheck:no self
local fairy = require "lobby/lcore/fairygui"
local logger = require "lobby/lcore/logger"
local urlpathsCfg = require "lobby/lcore/urlpathsCfg"
local httpHelper = require "lobby/lcore/httpHelper"
local proto = require "lobby/scripts/proto/proto"
local dialog = require "lobby/lcore/dialog"
local errHelper = require "lobby/lcore/lobbyErrHelper"
local CS = _ENV.CS

local EmailView = {}

function EmailView.new()
    if EmailView.unityViewNode then
        logger.debug("EmailView ---------------------")
    else
        _ENV.thisMod:AddUIPackage("lobby/fui_email/lobby_email")
        local viewObj = _ENV.thisMod:CreateUIObject("lobby_email", "emailView")

        EmailView.unityViewNode = viewObj

        local win = fairy.Window()
        win.contentPane = EmailView.unityViewNode

        EmailView.win = win
        EmailView.win:Show()

        -- 由于win隐藏，而不是销毁，隐藏后和GRoot脱离了关系，因此需要
        -- 特殊销毁
        _ENV.thisMod:RegisterCleanup(
            function()
                win:Dispose()
            end
        )
    end

    EmailView:initView()

    return EmailView
end

function EmailView:onMsg()
    if EmailView.unityViewNode then
        self:loadEmail()
    end
end

function EmailView:initView()
    -- body
    local clostBtn = self.unityViewNode:GetChild("closeBtn")
    clostBtn.onClick:Set(
        function()
            self:destroy()
        end
    )

    self.emailContent = self.unityViewNode:GetChild("textComponent"):GetChild("text")
    self.emailTitle = self.unityViewNode:GetChild("title")

    --附件列表
    self.attachmentsList = self.unityViewNode:GetChild("emailAttachmentList").asList
    self.attachmentsList.itemRenderer = function(index, obj)
        self:renderAttachmentListItem(index, obj)
    end
    self.attachmentsList:SetVirtual()

    -- 邮件列表
    self.list = self.unityViewNode:GetChild("mailList").asList
    self.list.itemRenderer = function(index, obj)
        self:renderPhraseListItem(index, obj)
    end
    self.list:SetVirtual()

    -- 拉取邮件
    self:loadEmail()
end

-- 更新邮件列表
function EmailView:updateList(emailRsp)
    self.dataMap = {}
    for i, email in ipairs(emailRsp.mails) do
        self.dataMap[i] = email
    end
    -- 个数
    self.list.numItems = #self.dataMap

    -- 默认选择第一个
    if #self.dataMap > 1 then
        self.list.selectedIndex = 0

        local email = self.dataMap[1]
        self:selectEmail(email, 0)
    end
end

function EmailView:selectEmail(email, index)
    self.emailContent.text = email.content
    self.emailTitle.text = email.title

    --刷新附件
    local selectedEmail = email
    self.selectedEmail = selectedEmail
    if selectedEmail ~= nil then
        self:updateAttachmentsView()
    end

    if email.isRead == false then
        self:setRead(email.id, index)
    end
end

-- 附件个数，现在暂时为1
function EmailView:updateAttachmentsView()
    self.attachmentsList.numItems = 1
end

function EmailView:renderAttachmentListItem(_, obj)
    local email = self.selectedEmail
    local attachment = email.attachments

    local count = obj:GetChild("count")
    count.text = attachment.num

    local readController = obj:GetController("c3")

    --设置是否领取
    if attachment.isReceive == true then
        readController.selectedIndex = 0
    else
        readController.selectedIndex = 1
    end

    obj.onClick:Set(
        function()
            if attachment.isReceive == false then
                self:takeAttachment(email)
            end
        end
    )
end

function EmailView:renderPhraseListItem(index, obj)
    local email = self.dataMap[index + 1]

    local readController = obj:GetController("c1")

    --是否已读
    if email.isRead == false then
        readController.selectedIndex = 0
    else
        readController.selectedIndex = 1
    end

    local title = obj:GetChild("title")
    title.text = "邮件"

    -- 空白按钮，为了点击列表，并且保留item被选择的效果
    local btn = obj:GetChild("spaceBtn")
    btn.onClick:Set(
        function()
            self:selectEmail(email, index)
        end
    )
end

--[[
    email:要领取附件的邮件
]]
function EmailView:takeAttachment(email)
    local tk = CS.UnityEngine.PlayerPrefs.GetString("token", "")
    local takeAttachmentUrl =
        urlpathsCfg.rootURL .. urlpathsCfg.receiveAttachment .. "?tk=" .. tk .. "&mailID=" .. email.id

    local cb = function()
        local obj = self.attachmentsList:GetChildAt(0)
        local readController = obj:GetController("c3")
        readController.selectedIndex = 0
        email.attachments.isReceive = true
    end

    self:emailRequest(takeAttachmentUrl, nil, cb)
end

--[[
    emailId:邮件ID
    listIndex:邮件列表的index,用来设置邮件的读取标志
]]
function EmailView:setRead(emailId, listIndex)
    local tk = CS.UnityEngine.PlayerPrefs.GetString("token", "")
    local setReadEmailUrl = urlpathsCfg.rootURL .. urlpathsCfg.setMailRead .. "?&tk=" .. tk .. "&mailID=" .. emailId

    local cb = function()
        local obj = self.list:GetChildAt(listIndex)
        local readController = obj:GetController("c1")
        readController.selectedIndex = 1
    end

    self:emailRequest(setReadEmailUrl, nil, cb)
end

-- 拉取邮件
function EmailView:loadEmail()
    local tk = CS.UnityEngine.PlayerPrefs.GetString("token", "")
    local loadEmailUrl = urlpathsCfg.rootURL .. urlpathsCfg.loadMails .. "?&rt=1&tk=" .. tk
    local msg = "正在拉取邮件......"

    local cb = function(body)
        local emails = proto.decodeMessage("lobby.MsgLoadMail", body)
        self:updateList(emails)
    end

    self:emailRequest(loadEmailUrl, msg, cb)
end

--[[
    url:请求的URL
    msg:请求的diolog信息
    cb: 完成回调

]]
function EmailView:emailRequest(url, msg, cb)
    if url == nil then
        return
    end

    if msg ~= nil then
        dialog.showDialog(msg)
    end

    logger.debug("emailRequest url = ", url)

    local win = dialog.win
    httpHelper.get(
        win,
        url,
        function(req, resp)
            win:Hide()
            if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
                local httpError = errHelper.dumpHttpRespError(resp)
                if httpError == nil then
                    if resp.Data then
                        if cb ~= nil then
                            cb(resp.Data)
                        end
                    end
                end
                resp:Dispose()
            else
                local err = errHelper.dumpHttpReqError(req)
                if err then
                    dialog.showDialog(
                        err.msg,
                        function()
                        end
                    )
                end
            end
            req:Dispose()
        end
    )
end

function EmailView:destroy()
    self.unityViewNode:Dispose()

    self.win:Hide()
    self.win:Dispose()
    self.win = nil
    self.unityViewNode = nil
end

return EmailView
