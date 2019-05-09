--[[
    ProgressView 进度条
]]
--luacheck: no self
local UpdateProgress = {}
-- local mt = {__index = UpdateProgress}
local fairy = require "lobby/lcore/fairygui"
local logger = require "lobby/lcore/logger"
local lenv = require "lobby/lenv"
local dialog = require "lobby/lcore/dialog"
local CS = _ENV.CS

function UpdateProgress:new(modName, endCallBack)
	if UpdateProgress.unityViewNode then
        logger.debug("UpdateProgress ---------------------")
    else
        _ENV.thisMod:AddUIPackage("lobby/fui_lobby_progress_bar/lobby_progress_bar")
        local viewObj = _ENV.thisMod:CreateUIObject("lobby_progress_bar", "progressBar")

		UpdateProgress.unityViewNode = viewObj
		UpdateProgress.modName = modName
		UpdateProgress.endCallBack = endCallBack

        local win = fairy.Window()
        win.contentPane = UpdateProgress.unityViewNode
        UpdateProgress.win = win

        -- 由于win隐藏，而不是销毁，隐藏后和GRoot脱离了关系，因此需要
        -- 特殊销毁
        _ENV.thisMod:RegisterCleanup(
            function()
                win:Dispose()
            end
		)

		UpdateProgress.progressBar = UpdateProgress.unityViewNode:GetChild("n0")
    end

	UpdateProgress.win:Show()

	return UpdateProgress
end



function UpdateProgress:doUpgrade()
	if not self.modName then
		logger.error("UpdateProgress, self.modName == nil")
	end

	if not self.progressBar then
		logger.error("UpdateProgress, self.progressBar == nil")
	end

    -- 准备检查更新Lobby模块
    local urlpathsCfg = require "lobby/lcore/urlpathsCfg"
    logger.debug("urlpathsCfg.updateQuery:", urlpathsCfg.updateQuery)
    local updaterM = require "lobby/lcore/updater"
	local updater = updaterM:new(self.modName, urlpathsCfg.rootURL..urlpathsCfg.updateQuery, self.unityViewNode)

	local err
	local isNeedUpgrade

	err, isNeedUpgrade = updater:checkUpdate()

	-- 检查阶段就已经发生错误
	if err ~= nil then
		return err
	end

	-- 如果有更新，执行更新
    if isNeedUpgrade then

        self.progressBar.visible = true

		err = updater:doUpgrade(
                function(event, downloaded, total)
                    logger.debug(event, downloaded, total)
                    if downloaded then
                        self.progressBar.value = 100 * downloaded / total
                    end

                end
		)
	end

	-- 返回err
	return err
end

function UpdateProgress:isUpgradeEnable()
	-- 除非配置为强制启用更新（用于测试更新逻辑）
	if lenv.forceUseUpgrade then
		return true
	end

	-- 如果处于编辑器模式，则不启用更新
	local isEditor = CS.UnityEngine.Application.isEditor
	return not isEditor
end

---------------------------------------
--显示重连对话框，如果用户选择重试
--则return true，否则返回false
---------------------------------------
function UpdateProgress:showRetryMsgBox(msg)
	local retry = false
    dialog.coShowDialog(
        msg,
		function()
			retry = true
        end,
        function()
			retry = false
        end
	)

	return retry
end

function UpdateProgress:runCoroutine()
	logger.trace("mainEntryCoroutine()")

	-- 先显示启动背景
	local err = nil

	-- 如果使用更新
	if self:isUpgradeEnable() then
		local retry = true
		-- 失败时，不断重试
		while retry do
			-- 尝试检查和实施更新
			err = self:doUpgrade()
			if err ~= nil then
				-- 发生错误，询问是否重试
				retry = self:showRetryMsgBox(err.msg)
			else
				break
			end
		end
	end

	if self.endCallBack then
		self.endCallBack(err)
	end

	self:destroy()
end

function UpdateProgress:updateView()
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


function UpdateProgress:destroy()
    self.win:Hide()
    self.win:Dispose()
    self.unityViewNode = nil
    self.win = nil
end


return UpdateProgress
