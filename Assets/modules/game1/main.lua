local logger = require "lobby/lcore/logger"
local dialog = require "lobby/lcore/dialog"

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

-- local function testRecordUI()
-- 	_ENV.thisMod:AddUIPackage("game1/fgui/runfast")
-- 	RecordTotalView.showView()
-- end

local function testCreateRoom(roomInfo)
	logger.debug("testCreateRoom,roomInfo:", roomInfo)
	local singletonMod = require("scripts/singleton")
	local singleton = singletonMod.getSingleton()
	-- 启动cortouine
	local co =
		coroutine.create(
		function()
			local pp = _ENV.CS.UnityEngine.PlayerPrefs
			local serverUUID = roomInfo.gameServerID
			local userID = pp.GetString("userID", "")
			local myUser = {userID = userID}
			-- local roomInfo = {roomID = "monkey-room", roomNumber = "monkey"}
			singleton:tryEnterRoom(serverUUID, myUser, roomInfo)
		end
	)

	local r, err = coroutine.resume(co)
	if not r then
		logger.error(debug.traceback(co, err))
	end
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
			local roomInfo = {roomID = "monkey-room", roomNumber = "monkey"}
			singleton:tryEnterRoom(serverUUID, myUser, roomInfo)
		end
	)

	local r, err = coroutine.resume(co)
	if not r then
		logger.error(debug.traceback(co, err))
	end
end

local function testReplay(replayData)
	local singletonMod = require("scripts/singleton")
	local singleton = singletonMod.getSingleton()
	-- 启动cortouine
	local proto = require "lobby/scripts/proto/proto"
	local record = proto.decodeMessage("lobby.MsgAccLoadReplayRecord", replayData)

	local co =
		coroutine.create(
		function()
			local pp = _ENV.CS.UnityEngine.PlayerPrefs
			local userID = pp.GetString("userID", "")
			local loadReply = {replayRecordBytes = record.replayRecordBytes}
			local chairID = 0
			singleton:tryEnterReplayRoom(userID, loadReply, chairID)
		end
	)

	local r, err = coroutine.resume(co)
	if not r then
		logger.error(debug.traceback(co, err))
	end
end

local function backToLobby()
	-- 清理界面
	local fairy = require "lobby/lcore/fairygui"
	fairy.GRoot.inst:CleanupChildren()
	-- 退回大厅
	_ENV.thisMod:BackToLobby()
end

local function loadRecord(recordID)
	local hh = require "lobby/lcore/httpHelper"
	local errHelper = require "lobby/lcore/lobbyErrHelper"
	local CS = _ENV.CS
	local urlpathsCfg = require "lobby/lcore/urlpathsCfg"

	dialog.showDialog("downloading ...")

	local win = dialog.win

	local tk = CS.UnityEngine.PlayerPrefs.GetString("token", "")
	local loadGameRecordUrl = urlpathsCfg.rootURL .. urlpathsCfg.lrprecord .. "?&rt=1&tk=" .. tk .. "&rid=" .. recordID

	logger.debug("loadRecord loadGameRecordUrl:", loadGameRecordUrl)

	local err
	local co = coroutine.running()

	hh.get(
		win,
		loadGameRecordUrl,
		function(req, resp)
			local httpError
			local respBytes
			if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
				httpError = errHelper.dumpHttpRespError(resp)
				if httpError == nil then
					respBytes = resp.Data
					resp:Dispose()
				end
			else
				httpError = errHelper.dumpHttpReqError(req)
			end

			req:Dispose()
			win:Hide()

			if httpError ~= nil then
				logger.debug("download replay record failed:", httpError)
				err = httpError
			else
				testReplay(respBytes)
			end

			local r, error = coroutine.resume(co)
			if not r then
				logger.error(debug.traceback(co, error))
			end
		end
	)

	coroutine.yield()

	return err
end

---------------------------------------
--显示重连对话框，如果用户选择重试
--则return true，否则返回false
---------------------------------------
local function showRetryMsgBox(msg)
	logger.debug("showRetryMsgBox error = ", msg)
	local retry
	dialog.coShowDialog(
		msg,
		function()
			retry = true
		end,
		function()
			retry = false
			backToLobby()
		end
	)

	return retry
end

local function runCoroutine(recordID)
	local err
	local retry = true
	-- 失败时，不断重试
	while retry do
		-- 下载回拨记录
		err = loadRecord(recordID)
		if err ~= nil then
			-- 发生错误，询问是否重试
			retry = showRetryMsgBox("下载失败，是否重试")
		else
			break
		end
	end
end

-- 创建一个routine 去下载回拨记录
local function loadRecordCoroutine(recordID)
	local co =
		coroutine.create(
		function()
			runCoroutine(recordID)
		end
	)

	local r, err = coroutine.resume(co)
	if not r then
		logger.error(debug.traceback(co, err))
	end
end

-- local function goTestReplay()
-- 	local hh = require "lobby/lcore/httpHelper"
-- 	local errHelper = require "lobby/lcore/lobbyErrHelper"
-- 	local dialog = require "lobby/lcore/dialog"
-- 	dialog.showDialog("downloading ...")
-- 	local win = dialog.win

-- 	local recordID = "536c779e-0f5c-4b6a-9364-42da53817c1c"
-- 	local url = "http://localhost:3001/game/uuid/support/exportRR?account=linguohua&password=jFPwopNA&recordID="
-- 	url = url .. recordID
-- 	local CS = _ENV.CS
-- 	hh.get(
-- 		win,
-- 		url,
-- 		function(req, resp)
-- 			local httpError
-- 			local respBytes
-- 			if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
-- 				httpError = errHelper.dumpHttpRespError(resp)
-- 				--没有HTTP错误则对比MD5，并保存文件
-- 				if httpError == nil then
-- 					respBytes = resp.Data
-- 					resp:Dispose()
-- 				end
-- 			else
-- 				httpError = errHelper.dumpHttpReqError(req)
-- 			end

-- 			req:Dispose()

-- 			win:Hide()

-- 			if httpError ~= nil then
-- 				logger.error("download replay record failed:", httpError)
-- 			else
-- 				testReplay(respBytes)
-- 			end
-- 		end
-- 	)
-- end

local function main()
	logger.info("game ", version.MODULE_NAME, " startup, version:", version.VER_STR)
	_ENV.MODULE_NAME = version.MODULE_NAME

	local jsonString = _ENV.launchArgs
	if jsonString ~= nil then
		local rapidjson = require("rapidjson")
		local json = rapidjson.decode(jsonString)
		logger.debug("launchArgs:", json)
		if json.gameType == "1" then
			goTestGame()
		elseif json.gameType == "3" then
			--goTestReplay()
			--testRecordUI()
			--goTestReplay()
			loadRecordCoroutine(json.rid)
		elseif json.gameType == "4" then
			testCreateRoom(json.roomInfo)
		end
	end

	-- testGame1UI()
end

main()
