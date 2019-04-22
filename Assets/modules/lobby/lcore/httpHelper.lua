--[[
Description:
	httpHelper.lua http相关的辅助，例如GET/POST，WEBSOCKET等
		最主要的目的是，让HTTP请求绑定到FairyGUI组件上，组件销毁时，请求必然销毁，
		否则，如果逻辑代码在界面销毁后忘记销毁HTTP请求，则等到请求完成后，要操作界面时界面
		已经销毁，就会出错
Note:
	函数名，变量名以camel case风格命名。
	不允许全局变量。

	类名可以大写开头。
--]]
-- 组件集合
local compTable = {}

local HTTPHelper = {}

local CS = _ENV.CS
local logger = require "lobby/lcore/logger"

local wsClean = function(w)
	w.OnOpen = nil
	w.OnClosed = nil
	w.OnError = nil
	w.OnMessage = nil
	w.OnBinary = nil
end

local function removeComp(component)
	--logger.debug("removeComp:", component)

	for k, v in ipairs(compTable) do
		if v.comp == component then
			logger.debug("remove component at pos:", k)
			table.remove(compTable, k)

			-- 清理所有挂于component下的未完成的请求
			for _, v1 in ipairs(v.reqWrappers) do
				if v1.isWS then
					logger.debug("remove component cleanup websocket")
					-- 清空回调
					wsClean(v1.ws)
					-- 关闭websocket
					v1.ws:Close()
				else
					logger.debug("remove component cleanup http request")
					-- 清空回调
					v1.req.Callback = nil
					v1.req.OnProgress = nil
					-- 取消请求
					v1.req:Abort()
				end
			end

			break
		end
	end
end

local function onDisposing(c)
	--参数c是EventContext, c.data是组件对象
	removeComp(c.data)
end

local function addReq(component, reqWrapper)
	local compWrapper = nil
	for _, v in ipairs(compTable) do
		if v.comp == component then
			compWrapper = v
			break
		end
	end

	if compWrapper == nil then
		compWrapper = {comp = component, reqWrappers = {}}
		table.insert(compTable, compWrapper)

		--logger.debug("addReq subscribe component onDisposing:", component)
		component.onDisposing:Add(onDisposing)
	end

	table.insert(compWrapper.reqWrappers, reqWrapper)
	reqWrapper.compWrapper = compWrapper

	--logger.debug("addReq:", reqWrapper)
end

local function removeReq(reqWrapper)
	--logger.debug("removeReq:", reqWrapper)
	local compWrapper = reqWrapper.compWrapper
	for k, v in ipairs(compWrapper.reqWrappers) do
		if v == reqWrapper then
			logger.debug("remove reqWrapper at pos:", k)
			table.remove(compWrapper.reqWrappers, k)
			break
		end
	end

	if reqWrapper.isWS then
		-- 清空回调
		wsClean(reqWrapper.ws)
	else
		-- 清空回调
		reqWrapper.req.Callback = nil
		reqWrapper.req.OnProgress = nil
	end
end

local function newHttpRequest(component, url, method, onFinished)
	local reqWrapper = {}
	local req =
		CS.BestHTTP.HTTPRequest(
		CS.System.Uri(url),
		method,
		function(req, resp)
			removeReq(reqWrapper)
			onFinished(req, resp)
		end
	)

	reqWrapper.req = req

	addReq(component, reqWrapper)
	return reqWrapper
end

function HTTPHelper.getWithProgress(component, url, onFinished, onProgress)
	local reqWrapper = newHttpRequest(component, url, CS.BestHTTP.HTTPMethods.Get, onFinished)
	reqWrapper.req.OnProgress = onProgress

	reqWrapper.req:Send()

	return reqWrapper
end

function HTTPHelper.get(component, url, onFinished)
	local reqWrapper = newHttpRequest(component, url, CS.BestHTTP.HTTPMethods.Get, onFinished)
	reqWrapper.req:Send()

	return reqWrapper
end

function HTTPHelper.websocket(component, url)
	local ws = CS.BestHTTP.WebSocket.WebSocket(CS.System.Uri(url))
	local reqWrapper = {ws = ws, isWS = true}
	addReq(component, reqWrapper)

	return reqWrapper
end

function HTTPHelper.cleanWebsocket(reqWrapper)
	removeReq(reqWrapper)
end

return HTTPHelper
