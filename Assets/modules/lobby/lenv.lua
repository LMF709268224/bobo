--[[
Description:
	LEnv.lua lobby当前的环境配置

Note:
	函数名，变量名以camel case风格命名。
	不允许全局变量。

	类名可以大写开头。
--]]

local LEnv = {}

local version = require 'lobby/version'

--Lobby模块版本号
LEnv.VER_STR = version.VER_STR

--日志等级
LEnv.loglevel = 0
--对应BestHTTP.Information
LEnv.bestHTTP = {
	loglevel = 1
}

--强制更新
LEnv.forceUseUpgrade = true

LEnv.URL = {
	updateQuery='http://localhost:3001/lobby/upgrade/query',
	updateDownload = 'http://localhost:3001/lobby/upgrade/download'
}

return LEnv
