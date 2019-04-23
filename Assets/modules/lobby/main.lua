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

-- c# 会调用本函数切换回大厅
_ENV.backToLobby = function()
	logger.debug("backToLobby")
	fairy.GRoot.inst:AddChild(mylobbyView)
	mylobbyView = nil
end

-- 子游戏模块会调用本函数（通过跨lua虚拟机调用）
_ENV.gameServerScheme = function()
	-- 以后这个host也统一到某个lua文件中，由它结合防DDOS流程来给出
	return 'ws://localhost:3001'
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

-- local function showLoginView()
-- 	local loginView = require "lobby/scripts/login/loginView"
-- 	loginView.showLoginView()
-- end

local function main()
	local lobbyVer = lenv.VER_STR
	local csharpVer = CS.Version.VER_STR

	--日志等级设置
	logger.level = lenv.loglevel
	CS.BestHTTP.HTTPManager.Logger.Level = lenv.bestHTTP.loglevel

	logger.warn("lobby/Boot begin, lobby version:", lobbyVer, ",csharp version:", csharpVer)

	_ENV.thisMod:RegisterCleanup(shutdownCleanup)


	-- 启动cortouine
	-- local co = coroutine.create(mainEntryCoroutine)
	-- local r, err = coroutine.resume(co)
	-- if not r then
	-- logger.error(debug.traceback(co, err))
	-- end

	testLobbyUI()

	-- showLoginView()

end

main()
