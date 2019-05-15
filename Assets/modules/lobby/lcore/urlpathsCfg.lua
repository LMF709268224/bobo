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
	updateDownload = "http://localhost:8080",
	gameWebsocketMonkey = "/game/%s/ws/monkey",
	gameWebsocketPlay = "/game/%s/ws/play",
	rootURL = "http://121.196.210.106:30002",
	quicklyLogin = "/lobby/uuid/quicklyLogin",
	accountLogin = "/lobby/uuid/accountLogin",
	wxLogin = "/lobby/uuid/wxLogin",
	register = "/lobby/uuid/register",
	chat = "/lobby/uuid/chat",
	lobbyWebsocket = "ws://121.196.210.106:30002/lobby/uuid/ws",
	-- 创建房间
	createRoom = "/lobby/uuid/createRoom",
	loadRoomPriceCfgs = "/lobby/uuid/loadPrices",

	requestRoomInfo = "/lobby/uuid/requestRoomInfo",

	--战绩
	lrproom = "/lobby/uuid/lrproom",
	lrprecord = "/lobby/uuid/lrprecord",

	-- 邮件
	loadMails = "/lobby/uuid/loadMails",
	setMailRead = "/lobby/uuid/setMailRead",
	deleteMail = "/lobby/uuid/deleteMail",
	receiveAttachment = "/lobby/uuid/receiveAttachment"
}

return UrlPaths
