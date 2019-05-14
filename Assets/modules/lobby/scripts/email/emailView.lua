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
end

function EmailView:initView()
    -- body
    local clostBtn = self.unityViewNode:GetChild("closeBtn")
    clostBtn.onClick:Set(
        function()
            self:destroy()
        end
    )

    self.list = EmailView.unityViewNode:GetChild("mailList").asList
    self.list.itemRenderer = function(index, obj)
        self:renderPhraseListItem(index, obj)
    end
    self.list:SetVirtual()
    --self.list.numItems = 50
    self:loadEmail()
end

-- 更新列表
function EmailView:updateList(emailRsp)
    logger.debug("emailRsp = ", emailRsp)
    self.dataMap = {}
    for i, email in ipairs(emailRsp) do
        local r = proto.decodeMessage("lobby.MsgReplayRoom", email.replayRoomBytes)
        self.dataMap[i] = r
    end
    self.list.numItems = #self.dataMap
end

function EmailView:renderPhraseListItem(index, obj)
    --local email = self.dataMap[index + 1]

    local btn = obj:GetChild("spaceBtn")
    btn.onClick:Set(
        function()
            logger.debug("renderPhraseListItem index:", index)
        end
    )
end

function EmailView:loadEmail()
    -- 拉取邮件
    local tk = CS.UnityEngine.PlayerPrefs.GetString("token", "")
    local loadEmailUrl = urlpathsCfg.rootURL .. urlpathsCfg.loadMails .. "?&rt=1&tk=" .. tk
    logger.debug("loadGameRecord loadEmailUrl:", loadEmailUrl)
    -- 加滚动条
    dialog.showDialog("正在拉取邮件......")
    local win = dialog.win
    httpHelper.get(
        win,
        loadEmailUrl,
        function(req, resp)
            win:Hide()
            if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
                local httpError = errHelper.dumpHttpRespError(resp)
                if httpError == nil then
                    if resp.Data then
                        local gameRecords = proto.decodeMessage("lobby.MsgAccLoadReplayRoomsReply", resp.Data)
                        -- 初始化数据
                        self:updateList(gameRecords)
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
