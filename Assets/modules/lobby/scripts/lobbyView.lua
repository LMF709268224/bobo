--[[
Description:
	lobbyView.lua 大厅

Note:
	函数名，变量名以camel case风格命名。
	不允许全局变量。

	类名可以大写开头。
--]]
--luacheck: no self
local LobbyView = {}
local logger = require "lobby/lcore/logger"
local fairy = require "lobby/lcore/fairygui"
local msgCenter = require "lobby/scripts/msgCenter"
local urlpathsCfg = require "lobby/lcore/urlpathsCfg"
local CS = _ENV.CS

function LobbyView:show()
    if LobbyView.viewNode then
        logger.debug("LobbyView:show")
    else
        logger.debug("LobbyView viewNode is nil.")
        _ENV.thisMod:AddUIPackage("lobby/fui/lobby_main")
        local view = _ENV.thisMod:CreateUIObject("lobby_main", "Main")
        fairy.GRoot.inst:AddChild(view)
        LobbyView.viewNode = view

        -- gooo = view

        -- local createBtn = view:GetChild("n4")
        -- createBtn.onClick:Set(LobbyView.onCreateClick)
        -- local win = fairy.Window()
        -- win.contentPane = view
        -- win.modal = true

        -- LobbyView.viewNode = view
        -- LobbyView.win = win

        LobbyView:initView()
    end

    local tk = CS.UnityEngine.PlayerPrefs.GetString("token", "")
    local url = urlpathsCfg.lobbyWebsocket .. "?tk=" .. tk

    logger.debug("lobby websocket url:", url)

    local lobbyMsgCenter = msgCenter:new(urlpathsCfg.lobbyWebsocket .. "?tk=" .. tk, LobbyView.viewNode)
    LobbyView.msgCenter = lobbyMsgCenter

    logger.debug("msgCenter errCount:", lobbyMsgCenter.connectErrorCount)

    local co =
        coroutine.create(
        function()
            lobbyMsgCenter:start()
        end
    )

    local r, err = coroutine.resume(co)
    if not r then
        logger.error(debug.traceback(co, err))
    end

    -- LobbyView.win:Show()
end

function LobbyView:initView()
    local friendBtn = self.viewNode:GetChild("n1")
    friendBtn.onClick:Set(
        function()
            self:onFriendClick()
        end
    )

    local createBtn = self.viewNode:GetChild("n4")
    createBtn.onClick:Add(
        function()
            self:onCreateClick()
        end
    )
end

function LobbyView:onFriendClick()
    local mylobbyView = fairy.GRoot.inst:GetChildAt(0)
	fairy.GRoot.inst:RemoveChild(mylobbyView)
	fairy.GRoot.inst:CleanupChildren()

	local parameters = {
		abc = "1"
	}

	local rapidjson = require("rapidjson")
	local jsonString = rapidjson.encode(parameters)
	_ENV.thisMod:LaunchGameModule("game1", jsonString)
end

function LobbyView:onCreateClick()
end

return LobbyView
