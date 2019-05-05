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
	updateQuery = "/lobby/uuid/upgradeQuery",
	updateDownload = "http://172.18.3.126:3002/webax/fileServer",
	gameWebsocketMonkey = "/game/%s/ws/monkey",
	gameWebsocketPlay = "/game/%s/ws/play",
	rootURL = "http://172.18.3.126:3002",
	quicklyLogin = "/lobby/uuid/quicklyLogin",
	accountLogin = "/lobby/uuid/accountLogin",
	wxLogin = "/lobby/uuid/wxLogin",
	register = "/lobby/uuid/register",
	chat = "/lobby/uuid/chat",
	lobbyWebsocket = "ws://172.18.3.126:3002/lobby/uuid/ws",
	createRoom = "/lobby/uuid/createRoom",
	--战绩
	lrproom = "/lobby/uuid/lrproom",
	lrprecord = "/lobby/uuid/lrprecord"
}

return UrlPaths
