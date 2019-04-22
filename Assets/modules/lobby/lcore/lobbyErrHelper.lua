--[[
Description:
	LobbyErrHelper.lua 大厅的错误码定义
	大厅使用1到20000编号，其中1到10000表示客户端本地错误，10001到20000表示服务器返回的错误


Note:
	函数名，变量名以camel case风格命名。
	不允许全局变量。
--]]
-- 错误码定义
local LobbyErrHelper = {
	ERR_SUCCESS = 0,
	ERR_HTTP_REQ_ERROR = 1,
	ERR_FILE_WRITE_FAILED = 2,
	ERR_DOWNLOAD_FAILED = 3,
	ERR_RESP_EMPTY_BODY = 4,
	ERR_JSON_DECODE = 5,
	ERR_JSON_CFG_MISSING = 6,
	ERR_SERVER404 = 10001,
	ERR_SERVER502 = 10002,
	ERR_CS_NEED_UPGRADE = 10003,
	ERR_LOBBY_NEED_UPGRADE = 10004,
	ERR_SERVER_UNKNOWN = 15000
}

-- HTTP Status对应错误码
local httpStatusCodeMap = {
	[404] = LobbyErrHelper.ERR_SERVER404,
	[502] = LobbyErrHelper.ERR_SERVER502
}

-- 错误码对应的中文描述
local errorStringMap = {
	[LobbyErrHelper.ERR_HTTP_REQ_ERROR] = "HTTP请求失败，请确保网络有效",
	[LobbyErrHelper.ERR_SERVER404] = "HTTP请求失败404，资源不存在",
	[LobbyErrHelper.ERR_SERVER502] = "HTTP请求失败502，服务器异常"
}

local logger = require "lobby/lcore/logger"

-- 获取错误码的中文描述
function LobbyErrHelper.errMsg(errCode)
	if errCode > 20000 then
		return "错误码[" .. errCode .. "]不属于大厅模块"
	end

	local msg = errorStringMap[errCode]
	if msg == nil then
		msg = "大厅模块无法找到对应错误码[" .. errCode .. "]的文本解析"
	end

	return msg
end

-- 转换http response的错误码
function LobbyErrHelper.dumpHttpRespError(resp)
	logger.trace("LobbyErrHelper.dumpHttpRespError, resp statusCode:" .. resp.StatusCode)

	if resp.IsSuccess then
		return nil
	end

	local statusCode = resp.StatusCode
	local errCode = httpStatusCodeMap[statusCode]

	if errCode == nil then
		logger.error("LobbyErrHelper.dumpHttpRespError, unknown statusCode:" .. statusCode)
		return {code = LobbyErrHelper.ERR_SERVER_UNKNOWN, msg = "HTTP RESP返回statusCode:" .. statusCode}
	end

	return {code = errCode, msg = LobbyErrHelper.errMsg(errCode)}
end

-- 转换http request的错误码
function LobbyErrHelper.dumpHttpReqError(req)
	logger.trace("LobbyErrHelper.dumpHttpReqError, req state:" .. req.State:ToString())
	local ex = req.Exception
	local errMsg = nil
	if ex ~= nil then
		errMsg = ex.Message
		logger.trace("http request exception:" .. errMsg)
	end

	local errCode = LobbyErrHelper.ERR_HTTP_REQ_ERROR
	if errMsg == nil then
		errMsg = LobbyErrHelper.errMsg(errCode)
	end
	return {code = errCode, msg = errMsg}
end

return LobbyErrHelper
