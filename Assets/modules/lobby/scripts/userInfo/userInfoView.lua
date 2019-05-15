--[[
    -- 用户信息
]]
--luacheck:no self
local fairy = require "lobby/lcore/fairygui"
local logger = require "lobby/lcore/logger"
-- local urlpathsCfg = require "lobby/lcore/urlpathsCfg"
-- local httpHelper = require "lobby/lcore/httpHelper"
-- local proto = require "lobby/scripts/proto/proto"
-- local dialog = require "lobby/lcore/dialog"
-- local errHelper = require "lobby/lcore/lobbyErrHelper"
-- local CS = _ENV.CS

local UserInfoView = {}

function UserInfoView.new()
    -- body
    if UserInfoView.unityViewNode then
        logger.debug("UserInfoView ---------------------")
    else
        _ENV.thisMod:AddUIPackage("lobby/fui_user_info/lobby_user_info")
        local viewObj = _ENV.thisMod:CreateUIObject("lobby_user_info", "userInfoView")

        UserInfoView.unityViewNode = viewObj

        local win = fairy.Window()
        win.contentPane = UserInfoView.unityViewNode

        UserInfoView.win = win
        UserInfoView.win:Show()

        -- 由于win隐藏，而不是销毁，隐藏后和GRoot脱离了关系，因此需要
        -- 特殊销毁
        _ENV.thisMod:RegisterCleanup(
            function()
                win:Dispose()
            end
        )
    end

    UserInfoView:initView()

    return UserInfoView
end

function UserInfoView:initView()
    -- body
    local clostBtn = self.unityViewNode:GetChild("closeBtn")
    clostBtn.onClick:Set(
        function()
            self:destroy()
        end
    )

    local pp = _ENV.CS.UnityEngine.PlayerPrefs

    local item = self.unityViewNode:GetChild("nick")
    local itemName = item:GetChild("item")
    itemName.text = "昵称:"

    local itemText = item:GetChild("text")
    local name = pp.GetString("nickName")
    if name == nil or #name < 1 then
        itemText.text = "默认用户名字"
    else
        itemText.text = pp.GetString("nickName")
    end

    item = self.unityViewNode:GetChild("id")
    itemName = item:GetChild("item")
    itemName.text = "ID:"

    itemText = item:GetChild("text")
    itemText.text = pp.GetString("userID")

    local genderCtrl = self.unityViewNode:GetController("gender")
    local gender = pp.GetString("sex")
    logger.debug("gender -----------------= ", gender)
    genderCtrl.selectedIndex = gender
end

function UserInfoView:destroy()
    self.unityViewNode:Dispose()

    self.win:Hide()
    self.win:Dispose()
    self.win = nil
    self.unityViewNode = nil
end

return UserInfoView
