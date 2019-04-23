--[[
Description:
	urlpathsCfg.lua 整个项目的URL PATH配置
Note:
	函数名，变量名以camel case风格命名。
	不允许全局变量。

	类名可以大写开头。
--]]
local UrlPaths = {
	-- updateQuery = "/lobby/upgrade/query",
	updateQuery = "/lobby/uuid/trust/upgradeQuery",
	updateDownload = "/lobby/upgrade/download",
	gameWebsocketMonkey = "/game/%s/ws/monkey",
	gameWebsocketPlay = "/game/%s/ws/play",
	rootURL = "http://localhost:3002",
	quicklyLogin = "/lobby/uuid/trust/quicklyLogin",
	accountLogin = "/lobby/uuid/trust/accountLogin",
	wxLogin = "/lobby/uuid/trust/wxLogin",
	register = "/lobby/uuid/trust/register"
}

return UrlPaths
