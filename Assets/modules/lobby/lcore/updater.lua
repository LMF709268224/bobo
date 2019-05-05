--[[
Description:
	Updater.lua 更新逻辑，用于更新某个模块（一个或多个assets bundle）

Note:
	函数名，变量名以camel case风格命名。
	不允许全局变量。
--]]
--luacheck: no self
local Updater = {}
local mt = {__index = Updater}
local CS = _ENV.CS

-- 需要使用到的外部模块
local logger = require "lobby/lcore/logger"
local urlEncoder = require "lobby/lcore/urlEncode"
local errHelper = require "lobby/lcore/lobbyErrHelper"
local rapidjson = require("rapidjson")
local batchDl = require "lobby/lcore/batchDownloader"
local httpHelper = require "lobby/lcore/httpHelper"
local urlpathsCfg = require "lobby/lcore/urlpathsCfg"

-- 进度节点定义
Updater.PROGRESS_GET_CFG = 1
Updater.PROGRESS_DOWNLOAD = 2
Updater.PROGRESS_INSTALL = 3

function Updater:new(modName, remoteURL, component)
	local updater = {modName = modName, remoteURL = remoteURL, component = component}

	-- version data
	local lobbyVersion = require "lobby/version"
	local modVersion = require(modName .. "/version")
	updater.modVersion = modVersion
	updater.lobbyVersion = lobbyVersion

	local writeAbleDir = CS.UnityEngine.Application.persistentDataPath
	updater.upgradePath = writeAbleDir .. "/" .. modName .. "_Upgrade"

	--确定模块的旧路径
	local writeAbleOldPath = writeAbleDir .. '/modules/' .. modName
	if CS.System.IO.Directory.Exists(writeAbleOldPath) then
		updater.oldPath = writeAbleOldPath
		updater.oldWriteAble = true
	else
		local readonlyOldPath = CS.UnityEngine.Application.streamingAssetsPath
		updater.oldPath = readonlyOldPath .. "/modules/" .. modName
		updater.oldWriteAble = false
	end

	return setmetatable(updater, mt)
end

function Updater:constructQueryString()
	local qs = "qMod=" .. urlEncoder.encode(self.modName) -- current module name
	qs = qs .. "&modV=" .. urlEncoder.encode(self.modVersion.VER_STR) -- current module version
	qs = qs .. "&csVer=" .. urlEncoder.encode(CS.Version.VER_STR) -- csharp core version
	qs = qs .. "&lobbyVer=" .. urlEncoder.encode(self.lobbyVersion.VER_STR) -- lobby version
	qs = qs .. "&operatingSystem=" .. urlEncoder.encode(CS.UnityEngine.SystemInfo.operatingSystem) -- system name
	qs = qs .. "&operatingSystemFamily=" .. urlEncoder.encode(CS.UnityEngine.SystemInfo.operatingSystemFamily:ToString())
	-- system family
	qs = qs .. "&deviceUniqueIdentifier=" .. urlEncoder.encode(CS.UnityEngine.SystemInfo.deviceUniqueIdentifier)
	-- mobile device id
	qs = qs .. "&deviceName=" .. urlEncoder.encode(CS.UnityEngine.SystemInfo.deviceName) -- device name
	qs = qs .. "&deviceModel=" .. urlEncoder.encode(CS.UnityEngine.SystemInfo.deviceModel) -- device mode
	qs = qs .. "&network=" .. urlEncoder.encode(CS.NetHelper.NetworkTypeString()) -- device network type

	return qs
end

function Updater:diffCfgs(_, remoteJSON)
	-- 主要是检查哪些需要保留，哪些需要更新
	local oldAbMaps = {}
	local upgrades = {}
	local uptodates = {}
	for _, newAB in ipairs(remoteJSON.abList) do
		local abName = newAB.name
		local oldAb = oldAbMaps[abName]

		if oldAb == nil then
			logger.trace("Updater:diffCfgs, got new ab:", abName)
			table.insert(upgrades, newAB)
		else
			if newAB.md5 ~= oldAb.md5 then
				logger.trace("Updater:diffCfgs, got updated ab:", abName)
				table.insert(upgrades, newAB)
			else
				logger.trace("Updater:diffCfgs, keep old ab:", abName)
				table.insert(uptodates, oldAb)
			end
		end
	end

	logger.trace("Updater:diffCfgs, uptodates cnt:", #uptodates, ",upgrades cnt:", #upgrades)
	return uptodates, upgrades
end

function Updater:validateJSON(remoteJSON)
	for _, newAB in ipairs(remoteJSON.abList) do
		if newAB.md5 == nil then
			return {code = errHelper.ERR_JSON_CFG_MISSING, msg = "JSON的bundle配置缺少md5"}
		end

		if newAB.name == nil then
			return {code = errHelper.ERR_JSON_CFG_MISSING, msg = "JSON的bundle配置缺少name"}
		end

		if newAB.size == nil then
			return {code = errHelper.ERR_JSON_CFG_MISSING, msg = "JSON的bundle配置缺少Size"}
		end
	end

	return nil
end

function Updater:checkUpdate()
	logger.trace("Updater:checkUpdate, modName:", self.modName)
	-- 构建querystring，主要是带上系统信息、模块信息
	local qs = self:constructQueryString()

	-- 先从服务器加载配置，拼接URL
	local remoteURL = urlEncoder.urlConcatQueryString(self.remoteURL, qs)
	local respBytes = nil
	local httpError = nil

	local co = coroutine.running()
	-- 请求服务器获取模块更新信息
	httpHelper.get(
		self.component,
		remoteURL,
		function(req, resp)
			if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
				httpError = errHelper.dumpHttpRespError(resp)
				if httpError == nil then
					respBytes = resp.Data
				end
				resp:Dispose()
			else
				httpError = errHelper.dumpHttpReqError(req)
			end

			req:Dispose()
			local r, err = coroutine.resume(co)
			if not r then
				logger.error(debug.traceback(co, err))
			end
		end
	)
	coroutine.yield()

	-- 检查服务器HTTP返回结果
	if httpError ~= nil then
		return httpError
	end

	if respBytes == nil then
		return {code = errHelper.ERR_RESP_EMPTY_BODY, msg = "服务器返回空的json字符串"}
	end

	-- JSON decode得到远端json配置
	local remoteJSON = rapidjson.decode(respBytes)
	if remoteJSON == nil then
		-- 没有内容需要更新
		return {code = errHelper.ERR_JSON_DECODE, msg = "无法decode服务器返的json字符串"}
	end

	-- 检查是否需要更新csharp，或者lobby
	if remoteJSON.code ~= nil and remoteJSON.code ~= 0 then
		return {code = remoteJSON.code, msg = "更新配置json内容code不为0"}
	end

	-- 不需要更新
	if (not remoteJSON.abValid) then
		return nil, false
	end

	-- 检查JSON配置合法
	httpError = self:validateJSON(remoteJSON)
	if httpError ~= nil then
		return httpError
	end

	-- 读取并decode本地配置
	local localJSONPath = self.oldPath .. "/cfg.json"
	-- 如果本地不存在模块json文件，ReadFileAsBytes也会返回一个长度为0的数组
	local localBytes = CS.NetHelper.UnityWebRequestLocalGet(localJSONPath)
	local localJSON = rapidjson.decode(localBytes)

	-- 对比本地配置和远端配置
	-- uptodates保存着那些已经是最新的资源包，upgrades保存着那些需要更新的资源包
	local uptodates, upgrades = self:diffCfgs(localJSON, remoteJSON)

	-- 准备从服务器拉取更新包
	-- 计算所有资源的个数和大小并保存
	local totalSize = 0
	for _, ab in ipairs(upgrades) do
		totalSize = totalSize + ab.size
	end

	if totalSize == 0 then
		-- 没有内容需要更新
		return nil, false
	end

	self.totalSize = totalSize

	local downloadURL = urlpathsCfg.updateDownload .. "/" .. self.modName .. "/" .. remoteJSON.version
	for _, ab in ipairs(upgrades) do
		if ab.url == nil then
			ab.url = downloadURL .. "/" .. ab.name
			logger.trace("ab:" .. ab.name .. " downdload url:" .. ab.url)
		end
	end

	self.uptodates = uptodates
	self.upgrades = upgrades
	self.respBytes = respBytes

	return nil, true
end

function Updater:doUpgrade(progressHandler, retryConfirmHandler)
	logger.trace("Updater:doUpgrade, modName:", self.modName)

	-- 检查是否存在ModeName_Upgrade目录
	-- 是的话需要删除目录
	if CS.System.IO.Directory.Exists(self.upgradePath) then
		CS.System.IO.Directory.Delete(self.upgradePath)
	end

	-- 创建upgrade目录
	-- 下载到upgrade目录
	CS.System.IO.Directory.CreateDirectory(self.upgradePath)

	-- 通知外部开始拉取数据包
	progressHandler(Updater.PROGRESS_DOWNLOAD, 0, self.totalSize)

	-- 每下载完成一个，都保存起来，并做记录
	local upgrades = self.upgrades
	local totalCount = #upgrades
	local downloadedSize = 0
	local remains = {}
	for i, ab in ipairs(upgrades) do
		remains[i] = ab
	end

	local co = coroutine.running()
	local loop = true
	while loop and #remains > 0 do
		-- Batch下载，3个HTTP一批次
		local batch = batchDl.new(remains, self.upgradePath, 3, self.component)
		batch.progress = function(delta)
			downloadedSize = downloadedSize + delta
			progressHandler(Updater.PROGRESS_DOWNLOAD, downloadedSize, self.totalSize)
		end

		batch.completed = function()
			local r, err = coroutine.resume(co)
			if not r then
				logger.error(debug.traceback(co, err))
			end
		end

		batch:start()
		coroutine.yield()

		-- 剩余的没有下载的asset bundle
		remains = batch.remains

		if #remains > 0 then
			if retryConfirmHandler then
				-- 询问是否重试
				loop = retryConfirmHandler(totalCount, #remains)
			else
				loop = false
			end
		end
	end

	-- 无法下载所有更新包
	if #remains > 0 then
		return {
			code = errHelper.ERR_DOWNLOAD_FAILED,
			msg = "无法下载所有更新包,共:" .. totalCount .. ",剩余:" .. #remains
		}
	end

	-- 所有资源下载完成,通知外部开始安装
	progressHandler(Updater.PROGRESS_INSTALL)

	local uptodates = self.uptodates
	-- 需要保留的资源包，复制到upgrade目录
	for _, ab in ipairs(uptodates) do
		local from = self.oldPath .. "/" .. ab.name
		local to = self.upgradePath .. "/" .. ab.name
		CS.NetHelper.UnityWebRequestLocalCopy(from, to, true) -- true表示覆盖已有文件
	end

	-- 保存远端配置
	local upgradeJSONPath = self.upgradePath .. "/cfg.json"
	local result = CS.NetHelper.WriteBytesToFile(upgradeJSONPath, self.respBytes)
	if not result then
		return {code = errHelper.ERR_FILE_WRITE_FAILED, msg = "保存新的模块cfg.json失败"}
	end

	-- 删除老的模块目录
	if self.oldWriteAble then
		CS.System.IO.Directory.Delete(self.oldPath)
	else
		local modulesPath = CS.UnityEngine.Application.persistentDataPath .. '/modules'
		if not CS.System.IO.Directory.Exists(modulesPath) then
			CS.System.IO.Directory.CreateDirectory(modulesPath)
		end

		self.oldPath = modulesPath..'/'..self.modName
	end

	-- 重命名upgrade目录
	CS.System.IO.Directory.Move(self.upgradePath, self.oldPath)

	return nil
end

return Updater
