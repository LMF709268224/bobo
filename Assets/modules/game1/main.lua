local logger = require "lobby/lcore/logger"
local CreateRoomView = require "scripts/createRoomView"

logger.warn("i am game1")

local version = require "version"

-- 打印所有被C#引用着的LUA函数
-- local function print_func_ref_by_csharp()
-- 	local registry = debug.getregistry()
-- 	for k, v in pairs(registry) do
-- 		if type(k) == "number" and type(v) == "function" and registry[v] == k then
-- 			local info = debug.getinfo(v)
-- 			print(string.format("%s:%d", info.short_src, info.linedefined))
-- 		end
-- 	end
-- end

local function testCreateUI()
	_ENV.thisMod:AddUIPackage("game1/fgui/runfast")
	CreateRoomView.new()
end

local function goTestGame()
	local singletonMod = require("scripts/singleton")
	local singleton = singletonMod.getSingleton()
	-- 启动cortouine
	local co =
		coroutine.create(
		function()
			singleton:tryEnterRoom()
		end
	)

	local r, err = coroutine.resume(co)
	if not r then
		logger.error(debug.traceback(co, err))
	end
end

local function onGameExit()
	logger.trace('onGameExit:', version.MODULE_NAME)
	for k,_ in pairs(package.loaded) do
		package.loaded[k] = nil
	end
end

local function onGameEnter()
	logger.trace('onGameEnter:', version.MODULE_NAME)
	local env = {}
	local origin = _ENV
	local newenv = setmetatable({}, {
		__index = function (t, k)
			local v = env[k]
			if v == nil then return origin[k] end
			return v
		end,
		__newindex = env,
	})

	_ENV = newenv

	_ENV.thisMod:RegisterCleanup(onGameExit)
end

local function main()
	onGameEnter()

	logger.info("game ", version.MODULE_NAME, " startup, version:", version.VER_STR)
	_ENV.MODULE_NAME = version.MODULE_NAME

	local jsonString = _ENV.launchArgs
	if jsonString ~= nil then
		local rapidjson = require("rapidjson")
		local json = rapidjson.decode(jsonString)
		logger.debug("launchArgs:",json)
		if json.abc == "1" then
			logger.debug("abc == 1")
			goTestGame()
		elseif json.abc == "2" then
			logger.debug("abc == 2")
			testCreateUI()
		end
	end

	-- testGame1UI()
end

main()
