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
local newRoomView = require "lobby/scripts/newRoom/newRoomView"
local joinRoomView = require "lobby/scripts/newRoom/joinRoomView"
local recordView = require "lobby/scripts/gameRecord/recordView"
local CS = _ENV.CS

function LobbyView:show()
    _ENV.thisMod:AddUIPackage("lobby/fui/lobby_main")
    local view = _ENV.thisMod:CreateUIObject("lobby_main", "Main")
    fairy.GRoot.inst:AddChild(view)
    LobbyView.viewNode = view

    LobbyView.msgHandler = {}

    LobbyView:initView()

    logger.debug("_ENV.thisMod.backToLobby")
    -- c# 会调用本函数切换回大厅
    _ENV.backToLobby = function()
        logger.debug("backToLobby")
        fairy.GRoot.inst:AddChild(view)
    end
    --由于view可能处于Groot之外，例如如果当前正在游戏模块中，
    --那么view就是隐藏的，在GRoot之外，因此需要额外销毁
    _ENV.thisMod:RegisterCleanup(
        function()
            view:Dispose()
        end
    )

    local tk = CS.UnityEngine.PlayerPrefs.GetString("token", "")
    local url = urlpathsCfg.lobbyWebsocket .. "?tk=" .. tk

    logger.debug("lobby websocket url:", url)

    local lobbyMsgCenter = msgCenter:new(urlpathsCfg.lobbyWebsocket .. "?tk=" .. tk, LobbyView)
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

function LobbyView:registerMsgHandler(ops, handler)
    if self.msgHandler[ops] ~= nil then
        logger.Error("handler aready exist, ops:", ops)
        return
    end

    self.msgHandler[ops] = handler
end

function LobbyView:initView()
    local friendBtn = self.viewNode:GetChild("n1")
    friendBtn.onClick:Set(
        function()
            self:onFriendClick()
        end
    )

    local createBtn = self.viewNode:GetChild("n4")
    createBtn.onClick:Set(
        function()
            self:onCreateClick()
        end
    )

    local coinBtn = self.viewNode:GetChild("n5")
    coinBtn.onClick:Set(
        function()
            self:onCoinClick()
        end
    )

    --local listView = self.viewNode:GetChild("n29")
    local dfTestBtn = self.viewNode:GetChild("n8")

    dfTestBtn.onClick:Set(
        function()
            self:openRecordView()
        end
    )

    local joinRoomBtn = self.viewNode:GetChild("n12")
    joinRoomBtn.onClick:Set(
        function()
            self:onJoinRoom()
        end
    )

    local createRoom = self.viewNode:GetChild("createRoom")
    createRoom.onClick:Set(
        function()
            self:onCreateRoom()
        end
    )
end

function LobbyView:ondfTestClick()
    local mylobbyView = fairy.GRoot.inst:GetChildAt(0)
    fairy.GRoot.inst:RemoveChild(mylobbyView)
    fairy.GRoot.inst:CleanupChildren()

    local parameters = {
        gameType = "1"
    }

    local rapidjson = require("rapidjson")
    local jsonString = rapidjson.encode(parameters)
    _ENV.thisMod:LaunchGameModule("game2", jsonString)
end

function LobbyView:onCoinClick()
    local mylobbyView = fairy.GRoot.inst:GetChildAt(0)
    fairy.GRoot.inst:RemoveChild(mylobbyView)
    fairy.GRoot.inst:CleanupChildren()

    local parameters = {
        gameType = "3"
    }

    local rapidjson = require("rapidjson")
    local jsonString = rapidjson.encode(parameters)
    _ENV.thisMod:LaunchGameModule("game1", jsonString)
end

function LobbyView:onFriendClick()
    local mylobbyView = fairy.GRoot.inst:GetChildAt(0)
    fairy.GRoot.inst:RemoveChild(mylobbyView)
    fairy.GRoot.inst:CleanupChildren()

    local parameters = {
        gameType = "1"
    }

    local rapidjson = require("rapidjson")
    local jsonString = rapidjson.encode(parameters)
    _ENV.thisMod:LaunchGameModule("game1", jsonString)
end

function LobbyView:onCreateClick()
    local mylobbyView = fairy.GRoot.inst:GetChildAt(0)
    fairy.GRoot.inst:RemoveChild(mylobbyView)
    fairy.GRoot.inst:CleanupChildren()

    local parameters = {
        gameType = "2"
    }

    local rapidjson = require("rapidjson")
    local jsonString = rapidjson.encode(parameters)
    _ENV.thisMod:LaunchGameModule("game1", jsonString)
end

function LobbyView:onJoinRoom()
    joinRoomView.new()
end

function LobbyView:onCreateRoom()
    newRoomView.new()
end

function LobbyView:openRecordView()
    recordView.new(self)
end

function LobbyView:enterRoom(modName, jsonString)
    local mylobbyView = fairy.GRoot.inst:GetChildAt(0)
    fairy.GRoot.inst:RemoveChild(mylobbyView)
    fairy.GRoot.inst:CleanupChildren()
    _ENV.thisMod:LaunchGameModule(modName, jsonString)
end

function LobbyView:dispatchMessage(lobbyMessage)
    local ops = lobbyMessage.Ops
    local handler = self.msgHandler[ops]
    if handler ~= nil then
        handler:onMsg(lobbyMessage.Data)
    end
end

return LobbyView
