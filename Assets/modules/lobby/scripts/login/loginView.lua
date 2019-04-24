--[[
    LoginView 登录界面
]]
--luacheck: no self
local LoginView = {}
local logger = require "lobby/lcore/logger"
local fairy = require "lobby/lcore/fairygui"
local progressView = require "lobby/scripts/login/progressView"
local urlpathsCfg = require "lobby/lcore/urlpathsCfg"
local httpHelper = require "lobby/lcore/httpHelper"
local proto = require "lobby/scripts/proto/proto"
local errHelper = require "lobby/lcore/lobbyErrHelper"
local CS = _ENV.CS

function LoginView.showLoginView()
    if LoginView.viewNode then
        logger.debug("showLoginView -----------")
    else
        logger.debug("showLoginView viewNode is nil.")
        _ENV.thisMod:AddUIPackage("lobby/fui_login/lobby_login")
        local view = fairy.UIPackage.CreateObject("lobby_login", "login")

        local win = fairy.Window()
        win.contentPane = view
        win.modal = true
        -- local screenWidth = CS.UnityEngine.Screen.width
        -- local screenHeight = CS.UnityEngine.Screen.height
        -- win:SetXY(screenWidth / 2, screenHeight / 2)

        LoginView.viewNode = view
        LoginView.win = win

        LoginView:initView()
        -- LoginView:testLists()
        -- 由于win隐藏，而不是销毁，隐藏后和GRoot脱离了关系，因此需要
        -- 特殊销毁
        _ENV.thisMod:RegisterCleanup(
            function()
                win:Dispose()
            end
        )

        view.onClick:Add(
            function()
                -- win:Hide()
            end
        )
    end

    LoginView.win:Show()

end

function LoginView:initView()
    -- button
    self.loginBtn = self.viewNode:GetChild("n2")
    self.weixinButton = self.viewNode:GetChild("n3")
    self.progressBar = self.viewNode:GetChild("n4")
    self.loginBtn.visible = false
    self.weixinButton.visible = false
    self.progressBar.value = 0
    self.progressBar.visible = false;

    -- self.progressBar = self.updateProgress:GetChild("bar")
    -- logger.error(self.progressBar)
    -- self.gprogress.value = 0
    self.loginBtn.onClick:Set(
        function()
            self:onQuicklyBtnClick()
        end
    )
    self.weixinButton.onClick:Set(
        function()
            self:onWeixinBtnClick()
        end
    )

    -- local progress = progressView.new(self)
    progressView:updateView(self)

end

function LoginView:onQuicklyBtnClick()
    logger.debug("onQuicklyBtnClick")
    self:quicklyLogin()
end

function LoginView:onWeixinBtnClick()
    logger.debug("onWeixinBtnClick")
end

function LoginView:msgBox()
	return false
end

function LoginView:updateComplete()
    self.progressBar.visible = false
    self.weixinButton.visible = true
    self.loginBtn.visible = true
end

function LoginView:saveQuicklyLoginReply(quicklyLoginReply)
    CS.UnityEngine.PlayerPrefs.SetString("account", quicklyLoginReply.account)

    local rapidjson = require("rapidjson")
    local jsonString = rapidjson.encode(quicklyLoginReply.userInfo)

    CS.UnityEngine.PlayerPrefs.SetString("userInfo", jsonString)
end

function LoginView:showLobbyView()
    _ENV.thisMod:AddUIPackage("lobby/fui/lobby_main")
	local view = fairy.UIPackage.CreateObject("lobby_main", "Main")
    fairy.GRoot.inst:AddChild(view)

    self.win:Hide()
    self.win:Dispose()
    self.unityViewNode = nil
    self.win = nil
end

function LoginView:quicklyLogin()
    local account = CS.UnityEngine.PlayerPrefs.GetString("account", "")
    local quicklyLoginURL = urlpathsCfg.rootURL..urlpathsCfg.quicklyLogin..'?&account='..account

    logger.trace("quicklyLogin, quicklyLoginURL:", quicklyLoginURL)

    httpHelper.get(
        self.viewNode,
        quicklyLoginURL,
        function (req, resp)
            if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
				local httpError = errHelper.dumpHttpRespError(resp)
				if httpError == nil then
                    local respBytes = resp.Data
                    local quicklyLoginReply = proto.decodeMessage("lobby.MsgQuicklyLoginReply", respBytes)
                    if quicklyLoginReply.result == 0 then
                        self:saveQuicklyLoginReply(quicklyLoginReply)
                        self:showLobbyView()
                    else
                        -- TODO: show error msg
                        logger.debug("quickly login error, errCode:", quicklyLoginReply.result)
                    end
                    -- logger.debug("quicklyLoginReply", quicklyLoginReply)

				end
				resp:Dispose()
			else
				errHelper.dumpHttpReqError(req)
			end

			req:Dispose()

        end
    )

end

function LoginView:accountLogin()

end

return LoginView
