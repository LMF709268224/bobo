--[[
    LoginView 登录界面
]]
--luacheck: no self
local LoginView = {}
local logger = require "lobby/lcore/logger"
local fairy = require "lobby/lcore/fairygui"
local updateView = require "./updateView"

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



    local co = coroutine.create(
        function()
            local update = updateView.new(LoginView.updateProgress, LoginView)
            update:updateView()
        end
    )

	local r, err = coroutine.resume(co)
	if not r then
	logger.error(debug.traceback(co, err))
	end

end

function LoginView:initView()
    -- button
    self.loginBtn = self.viewNode:GetChild("n2")
    self.weixinButton = self.viewNode:GetChild("n3")
    self.progressBar = self.viewNode:GetChild("n5")
    self.loginBtn.visible = false
    self.weixinButton.visible = false
    self.progressBar.value = 0
    self.progressBar.visible = false;

    -- self.progressBar = self.updateProgress:GetChild("bar")
    -- logger.error(self.progressBar)
    -- self.gprogress.value = 0
    self.loginBtn.onClick:Add(
        function()
            self:onQuicklyBtnClick()
        end
    )
    self.weixinButton.onClick:Add(
        function()
            self:onWeixinBtnClick()
        end
    )
end

function LoginView:onQuicklyBtnClick()
    logger.debug("onLoginBtnClick")
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

return LoginView
