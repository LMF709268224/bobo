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
local dialog = require "lobby/lcore/dialog"
local CS = _ENV.CS

function LoginView.showLoginView()
    _ENV.thisMod:AddUIPackage("lobby/fui_login/lobby_login")
    local view = _ENV.thisMod:CreateUIObject("lobby_login", "login")

    local win = fairy.Window()
    win.contentPane = view
    win.modal = true
    -- local screenWidth = CS.UnityEngine.Screen.width
    -- local screenHeight = CS.UnityEngine.Screen.height
    -- win:SetXY(screenWidth / 2, screenHeight / 2)

    LoginView.viewNode = view
    LoginView.win = win

    LoginView:initView()

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
    self.progressBar.visible = false

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

-- local function testUploadLog()
	-- local logPath = CS.UnityEngine.Application.persistentDataPath
	-- local logAName = "Player.log"
	-- local logA = logPath .. "/" .. logAName
	-- local logBName = "Player-prev.log"
	-- local logB = logPath .. "/" .. logBName
	-- -- 拼接日志文件名时，时间戳在前面，便于排序查看
	-- local zipfileName = "timestamp-userid-log.zip"
	-- local zipfile = logPath .. "/" .. zipfileName
	-- CS.System.IO.File.Delete(zipfile)

	-- local zip = CS.ZipStorer.Create(zipfile, "log")
	-- zip:AddFile(CS.ZipStorer.Compression.Deflate, logA, logAName, "logA")
	-- zip:AddFile(CS.ZipStorer.Compression.Deflate, logB, logBName, "logB")

	-- zip:Close()

	-- local zipContent = CS.System.IO.File.ReadAllBytes(zipfile)
	-- local httpHelper = require ('lobby/lcore/httpHelper')
	-- local reqWrapper = httpHelper.postRequest(LoginView.viewNode, 'http://localhost:3000/upload', function(req, resp)
		-- if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
			-- httpError = errHelper.dumpHttpRespError(resp)
			-- resp:Dispose()
		-- else
			-- httpError = errHelper.dumpHttpReqError(req)
		-- end

		-- if httpError ~= nil then
			-- logger.debug('upload log error', httpError)
		-- else
			-- logger.debug('upload log succeed')
		-- end
		-- req:Dispose()
	-- end)

	-- reqWrapper.req:AddBinaryData("file", zipContent, zipfileName)
	-- reqWrapper.req:Send()
-- end

function LoginView:onQuicklyBtnClick()
    logger.debug("onQuicklyBtnClick")
    self:quicklyLogin()

	-- 测试压缩文件
	--testUploadLog()
end

function LoginView:onWeixinBtnClick()
    logger.debug("onWeixinBtnClick")
end

function LoginView:updateComplete()
    self.progressBar.visible = false
    self.weixinButton.visible = true
    self.loginBtn.visible = true
end

function LoginView:saveQuicklyLoginReply(quicklyLoginReply)
    local pp = CS.UnityEngine.PlayerPrefs
    pp.SetString("account", quicklyLoginReply.account)
    pp.SetString("token", quicklyLoginReply.token)

    local userInfo = quicklyLoginReply.userInfo
    pp.SetString("userID", userInfo.userID)
    pp.SetString("nickName", userInfo.nickName)
    pp.SetString("sex", userInfo.sex)
    pp.SetString("province", userInfo.province)
    pp.SetString("city", userInfo.city)
    pp.SetString("country", userInfo.country)
    pp.SetString("headImgUrl", userInfo.headImgUrl)
    pp.SetString("phone", userInfo.phone)
end

function LoginView:showLobbyView()
    -- _ENV.thisMod:AddUIPackage("lobby/fui/lobby_main")
    -- local view = _ENV.thisMod:CreateUIObject("lobby_main", "Main")
    -- fairy.GRoot.inst:AddChild(view)

    local lobbyView = require "lobby/scripts/lobbyView"
    lobbyView.show()

    self:destroy()
end

function LoginView:destroy()
    self.win:Hide()
    self.win:Dispose()
    self.unityViewNode = nil
    self.win = nil
end

function LoginView:showLoginErrMsg(errCode)
    local errMsg = {}
    errMsg[proto.LoginError.ErrParamWechatCodeIsEmpty] = "获取微信code失败"
    errMsg[proto.LoginError.ErrLoadWechatUserInfoFailed] = "获取微信用户信息失败"
    errMsg[proto.LoginError.ErrParamAccountIsEmpty] = "输入账号不能为空"
    errMsg[proto.LoginError.ErrParamPasswordIsEmpty] = "输入密码不能为空"
    errMsg[proto.LoginError.ErrAccountNotExist] = "输入账号不存在"
    errMsg[proto.LoginError.ErrAccountNotSetPassword] = "账号没有设置密码，不能登录"
    errMsg[proto.LoginError.ErrPasswordNotMatch] = "账号没有设置密码，不能登录"

    local msg = errMsg[errCode]
    if not msg then
        msg = "登录失败"
    end

    dialog.showDialog(msg)
end

function LoginView:quicklyLogin()
    local account = CS.UnityEngine.PlayerPrefs.GetString("account", "")
    local quicklyLoginURL = urlpathsCfg.rootURL .. urlpathsCfg.quicklyLogin .. "?&account=" .. account
    -- logger.trace("quicklyLogin, quicklyLoginURL:", quicklyLoginURL)
    httpHelper.get(
        self.viewNode,
        quicklyLoginURL,
        function(req, resp)
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
                        self:showLoginErrMsg(quicklyLoginReply.result)
                    end
                    logger.debug("quicklyLoginReply", quicklyLoginReply)
                end
                resp:Dispose()
            else
               local err = errHelper.dumpHttpReqError(req)
               if err then
                   dialog.showDialog(err.msg)
               end
            end

            req:Dispose()
        end
    )
end

function LoginView:accountLogin()
end

return LoginView
