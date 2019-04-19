--[[
Description:
	BatchDownloader.lua 从服务器下载资源包，并发下载
	SingleDownloader 表示单个任务下载
	
Note:
	函数名，变量名以camel case风格命名。
	不允许全局变量。
--]]
local BatchDownloader = {}
local mt = { __index=BatchDownloader }

local SingleDownloader = {}
local mtS = {__index=SingleDownloader}

local logger = require 'lobby/Lcore/Logger'
local errHelper = require 'lobby/Lcore/LobbyErrHelper'

local function removeFromTable(t, e)
	for i, te in ipairs(t) do
		if te == e then
			table.remove(t,i)
			return
		end
	end
end

function SingleDownloader.new(ab,targetPath)
	local sd = {ab=ab,targetPath=targetPath}
	return setmetatable(sd, mtS)
end

function SingleDownloader:fire()
	local remoteURL = self.ab.url
	local sd = self
	self.httpError = nil

	--开始下载
	CS.NetHelper.HttpGetWithProgress(remoteURL, 
	function(req, resp) --finished回调
		local httpError = nil
		if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
			httpError = errHelper.dumpHttpRespError(resp)
			--没有HTTP错误则对比MD5，并保存文件
			if httpError == nil then
				local respBytes = resp.Data
				-- 对比MD5
				if sd.ab.md5 == CS.NetHelper.MD5(respBytes) then
					local targetPath = sd.targetPath
					--写入到文件
					local result = CS.NetHelper.WriteBytesToFile(targetPath..'/'..sd.ab.name, respBytes)
					if not result then
						httpError = {code=errHelper.ERR_FILE_WRITE_FAILED, msg='保存新的bundle数据包失败'}
					end
				else
					-- MD5不匹配
					httpError = {code=errHelper.ERR_MD5_NOT_MATCHED, msg='新的bundle数据包MD5检验失败'}
				end
				resp:Dispose()
			end
		else
			httpError = errHelper.dumpHttpReqError(req)
		end

		req:Dispose()
		
		self.httpError = httpError
		self.completedHandler(sd)
	end,
	function(req, downloaded) -- progress回调
		--通知外部进度更新
		sd.progressHandler(downloaded)
	end)
end

function BatchDownloader.new(remains, targetPath, cntPerBatch)
	cntPerBatch = cntPerBatch or 3
    local bd = { remains = remains, targetPath = targetPath, cntPerBatch = cntPerBatch}
    return setmetatable(bd, mt)
end

function BatchDownloader:onSingleDownloadCompleted(sd1)
	-- 从等待列表中移除
	removeFromTable(self.waiting, sd1)

	if sd1.httpError ~= nil then
		--增加到失败列表
		table.insert(self.failed, sd1)
		logger.error('Download ab:', sd1.ab.name,' failed, code:', sd1.httpError.code, ',msg:', sd1.httpError.msg)
	end

	-- 继续投递下一个请求
	if #self.remains > 0 then
		self:fireSingleDownloaders()
	end

	if #self.waiting < 1 then
		-- 没有等待中的下载了
		self.remains = self.failed -- remains现在指向failed
		self.completed()
	end
end

function BatchDownloader:fireSingleDownloaders()
	-- 启动N个下载任务
	local remainsCount = #self.remains
	local minI = remainsCount - self.cntPerBatch + 1
	if minI < 1 then
		minI = 1
	end

	for i = remainsCount, minI, -1 do
		local ab = self.remains[i]
		if ab == nil then
			break
		end

		local bd = self
		local sd = SingleDownloader.new(ab, self.targetPath)
		sd.completedHandler = function(sd1)
			bd:onSingleDownloadCompleted(sd1)
		end
		sd.progressHandler = self.progress
		
		--加入waiting列表
		table.insert(self.waiting, sd)
		--从remains删除
		table.remove(self.remains, i)

		--启动下载任务
		sd:fire()

		if #self.waiting >= self.cntPerBatch then
			break
		end
	end
end

function BatchDownloader:start()
	-- 初始化
	self.waiting = {}
	self.failed = {}
	
	self:fireSingleDownloaders()
end

return BatchDownloader
