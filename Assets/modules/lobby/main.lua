local logger = require "lobby/lcore/logger"
local lenv = require "lobby/lenv"
--local errHelper = require 'lobby/LobbyErrHelper'
local fairy = require "lobby/lcore/fairygui"
local CS = _ENV.CS

logger.warn("lobby main startup")

-- 打印所有被C#引用着的LUA函数
local function print_func_ref_by_csharp()
	local registry = debug.getregistry()
	for k, v in pairs(registry) do
		if type(k) == "number" and type(v) == "function" and registry[v] == k then
			local info = debug.getinfo(v)
			print(string.format("%s:%d", info.short_src, info.linedefined))
		end
	end
end

local mylobbyView = nil

-- 由C#调用
local function shutdownCleanup()
	if mylobbyView ~= nil then
		mylobbyView:Dispose()
	end

	logger.warn("lobby main cleanup")
	print_func_ref_by_csharp()
end

-- local function doUpgrade()
-- 	-- 准备检查更新Lobby模块
-- 	local updaterM = require "lobby/lcore/updater"
-- 	local updater = updaterM:new("lobby", lenv.URL.updateQuery)

-- 	local err
-- 	local isNeedUpgrade

-- 	err, isNeedUpgrade = updater:checkUpdate()

-- 	-- 检查阶段就已经发生错误
-- 	if err ~= nil then
-- 		return err
-- 	end

-- 	-- 如果有更新，执行更新
-- 	if isNeedUpgrade then
-- 		err =
-- 			updater:doUpgrade(
-- 			function(event, downloaded, total)
-- 				logger.debug(event, downloaded, total)
-- 			end
-- 		)
-- 	end

-- 	-- 返回err
-- 	return err, isNeedUpgrade
-- end

-- local function isUpgradeEnable()
-- 	-- 除非配置为强制启用更新（用于测试更新逻辑）
-- 	if lenv.forceUseUpgrade then
-- 		return true
-- 	end

-- 	-- 如果处于编辑器模式，则不启用更新
-- 	local isEditor = CS.UnityEngine.Application.isEditor
-- 	return not isEditor
-- end

-- local function msgBox()
-- 	return false
-- end

-- local function mainEntryCoroutine()
-- 	logger.trace("mainEntryCoroutine()")

-- 	-- 先显示启动背景
-- 	local err = nil
-- 	local upgraded = false

-- 	-- 如果使用更新
-- 	if isUpgradeEnable() then
-- 		local retry = true
-- 		-- 失败时，不断重试
-- 		while retry do
-- 			-- 尝试检查和实施更新
-- 			err, upgraded = doUpgrade()
-- 			if err ~= nil then
-- 				-- 发生错误，询问是否重试
-- 				retry = msgBox(err)
-- 			else
-- 				break
-- 			end
-- 		end
-- 	end

-- 	if err ~= nil then
-- 		-- 发生错误，退出
-- 		logger.error("Error:", err.msg, "Code:", err.code, ",程序将结束运行")
-- 		--_ENV.thisMod:AppExit()
-- 		return
-- 	end

-- 	if upgraded then
-- 		-- 更新完成后，卸载背景，并reboot
-- 		_ENV.thisMod:Reboot()
-- 		return
-- 	end

-- 	-- 开始登录
-- 	-- local login = require ('lobby/Login')
-- 	-- login()

-- 	--_ENV.thisMod:LaunchGameModule("game1")
-- end

-- local gooo = nil
-- local animation = require "lobby/lcore/animations"
local function onFriendClick()
	-- local anchor = gooo:GetChild('n32')
	-- animation.play('animations/Effects_huojian.prefab', gooo, anchor.x, anchor.y)

	--testGame1UI()
	mylobbyView = fairy.GRoot.inst:GetChildAt(0)
	fairy.GRoot.inst:RemoveChild(mylobbyView)
	fairy.GRoot.inst:CleanupChildren()

	local parameters = {
		abc = "1"
	}

	local rapidjson = require("rapidjson")
	local jsonString = rapidjson.encode(parameters)
	_ENV.thisMod:LaunchGameModule("game1", jsonString)
end

local function onCreateClick()
	--testGame1UI()
	mylobbyView = fairy.GRoot.inst:GetChildAt(0)
	fairy.GRoot.inst:RemoveChild(mylobbyView)
	fairy.GRoot.inst:CleanupChildren()

	local parameters = {
		abc = "2"
	}

	local rapidjson = require("rapidjson")
	local jsonString = rapidjson.encode(parameters)
	_ENV.thisMod:LaunchGameModule("game1", jsonString)
end

local function backToLobby()
	print("backToLobby")
	fairy.GRoot.inst:AddChild(mylobbyView)
	mylobbyView = nil
end

local function testLobbyUI()
	_ENV.thisMod:AddUIPackage("lobby/fui/lobby_main")
	local view = fairy.UIPackage.CreateObject("lobby_main", "Main")
	fairy.GRoot.inst:AddChild(view)

	local friendBtn = view:GetChild("n1")
	friendBtn.onClick:Add(onFriendClick)

	-- gooo = view

	local createBtn = view:GetChild("n4")
	createBtn.onClick:Add(onCreateClick)
end

local function main()
	local lobbyVer = lenv.VER_STR
	local csharpVer = CS.Version.VER_STR

	--日志等级设置
	logger.level = lenv.loglevel
	CS.BestHTTP.HTTPManager.Logger.Level = lenv.bestHTTP.loglevel

	logger.warn("lobby/Boot begin, lobby version:", lobbyVer, ",csharp version:", csharpVer)

	_ENV.thisMod:RegisterCleanup(shutdownCleanup)
	_ENV.backToLobby = backToLobby

	-- 启动cortouine
	-- local co = coroutine.create(mainEntryCoroutine)
	-- local r, err = coroutine.resume(co)
	-- if not r then
	-- logger.error(debug.traceback(co, err))
	-- end

	testLobbyUI()
end

main()
