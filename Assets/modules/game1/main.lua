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
			local pp = _ENV.CS.UnityEngine.PlayerPrefs
			local serverUUID = "uuid"
			local userID = pp.GetString("userID", "")
			local myUser = {userID = userID}
			local roomInfo = {roomID = "monkey-room"}
			singleton:tryEnterRoom(serverUUID, myUser, roomInfo)
		end
	)

	local r, err = coroutine.resume(co)
	if not r then
		logger.error(debug.traceback(co, err))
	end
end

local function main()
	logger.info("game ", version.MODULE_NAME, " startup, version:", version.VER_STR)
	_ENV.MODULE_NAME = version.MODULE_NAME

	local jsonString = _ENV.launchArgs
	if jsonString ~= nil then
		local rapidjson = require("rapidjson")
		local json = rapidjson.decode(jsonString)
		logger.debug("launchArgs:", json)
		if json.gameType == "1" then
			-- logger.debug("abc == 1")
			goTestGame()
		elseif json.gameType == "2" then
			-- logger.debug("abc == 2")
			testCreateUI()
		end
	end

	-- testGame1UI()
end

main()
