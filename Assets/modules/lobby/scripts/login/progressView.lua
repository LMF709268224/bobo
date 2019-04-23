--[[
    ProgressView 进度条
]]
--luacheck: no self
local ProgressView = {}
local mt = {__index = ProgressView}
local logger = require "lobby/lcore/logger"
local lenv = require "lobby/lenv"
local CS = _ENV.CS

function ProgressView:new(loginView)
	local progressView = {loginView = loginView}

	if not progressView.loginView then
		logger.debug("not progressView.loginView")
	end

	return setmetatable(progressView, mt)
end

function ProgressView:doUpgrade()
	if not self.loginView then
		logger.debug("not progressView.loginView")
	end

    -- 准备检查更新Lobby模块
    local urlpathsCfg = require "lobby/lcore/urlpathsCfg"
    logger.debug("urlpathsCfg.updateQuery:", urlpathsCfg.updateQuery)
    local updaterM = require "lobby/lcore/updater"
	local updater = updaterM:new("lobby", urlpathsCfg.rootURL..urlpathsCfg.updateQuery, self.loginView.viewNode)

	local err
	local isNeedUpgrade

	err, isNeedUpgrade = updater:checkUpdate()

	-- 检查阶段就已经发生错误
	if err ~= nil then
		return err
	end

	-- 如果有更新，执行更新
    if isNeedUpgrade then

        self.loginView.progressBar.visible = true

		err = updater:doUpgrade(
                function(event, downloaded, total)
                    logger.debug(event, downloaded, total)
                    if downloaded then
                        self.loginView.progressBar.value = 100 * downloaded / total
                    end

                end
		)
	end

	-- 返回err
	return err, isNeedUpgrade
end

function ProgressView:isUpgradeEnable()
	-- 除非配置为强制启用更新（用于测试更新逻辑）
	if lenv.forceUseUpgrade then
		return true
	end

	-- 如果处于编辑器模式，则不启用更新
	local isEditor = CS.UnityEngine.Application.isEditor
	return not isEditor
end

function ProgressView:runCoroutine()
	logger.trace("mainEntryCoroutine()")

	-- 先显示启动背景
	local err = nil
	local upgraded = false

	-- 如果使用更新
	if self:isUpgradeEnable() then
		local retry = true
		-- 失败时，不断重试
		while retry do
			-- 尝试检查和实施更新
			err, upgraded = self:doUpgrade()
			if err ~= nil then
				-- 发生错误，询问是否重试
				retry = self.loginView:msgBox(err)
			else
				break
			end
		end
	end

	if err ~= nil then
		-- 发生错误，退出
		logger.error("Error:", err.msg, "Code:", err.code, ",程序将结束运行")
		--_ENV.thisMod:AppExit()
		return
	end

	if upgraded then
		-- 更新完成后，卸载背景，并reboot
		_ENV.CS.Boot.Reboot()
        return
    else
        self.loginView:updateComplete()
	end
end

function ProgressView:updateView(loginView)
	self.loginView = loginView

	local co = coroutine.create(
        function()
            self:runCoroutine()
        end
    )

	local r, err = coroutine.resume(co)
	if not r then
	logger.error(debug.traceback(co, err))
	end
end

return ProgressView
