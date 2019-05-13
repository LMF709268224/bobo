--[[
    -- 邮件
]]
--luacheck:no self
local fairy = require "lobby/lcore/fairygui"
local logger = require "lobby/lcore/logger"
-- local urlpathsCfg = require "lobby/lcore/urlpathsCfg"
-- local httpHelper = require "lobby/lcore/httpHelper"
-- local proto = require "lobby/scripts/proto/proto"
-- local dialog = require "lobby/lcore/dialog"
-- local errHelper = require "lobby/lcore/lobbyErrHelper"

-- local subrecordView = require "lobby/scripts/gameRecord/subrecordView"
-- local CS = _ENV.CS

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

    EmailView:EmailView()
end

function EmailView:EmailView()
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

    self.list.numItems = 1000
end

function EmailView:renderPhraseListItem(index, obj)
    local title = obj:GetChild("title")
    local timeText = obj:GetChild("timeText")

    title.text = "item " .. index
    timeText.text = "5 Nov 2015 16:24:33"

    -- obj.onClick:Set(
    --     function()
    --         logger.debug("click dex  = ", index)
    --     end
    -- )
end

function EmailView:destroy()
    self.unityViewNode:Dispose()

    self.win:Hide()
    self.win:Dispose()
    self.win = nil
    self.unityViewNode = nil
end

return EmailView
