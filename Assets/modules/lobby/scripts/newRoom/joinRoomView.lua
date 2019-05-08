--luacheck:no self

local JoinRoomView = {}

local fairy = require "lobby/lcore/fairygui"
local logger = require "lobby/lcore/logger"
local urlpathsCfg = require "lobby/lcore/urlpathsCfg"
local httpHelper = require "lobby/lcore/httpHelper"
local proto = require "lobby/scripts/proto/proto"
local urlEncoder = require "lobby/lcore/urlEncode"
local dialog = require "lobby/lcore/dialog"
local updateProgress = require "lobby/scripts/newRoom/updateProgress"
local lobbyError = require "lobby/scripts/lobbyError"
local lenv = require "lobby/lenv"
local CS = _ENV.CS

function JoinRoomView.new()
    if JoinRoomView.unityViewNode then
        logger.debug("JoinRoomView ---------------------")
    else
        _ENV.thisMod:AddUIPackage("lobby/fui_join_room/lobby_join_room")
        local viewObj = _ENV.thisMod:CreateUIObject("lobby_join_room", "joinRoom")

        JoinRoomView.unityViewNode = viewObj

        local win = fairy.Window()
        win.contentPane = JoinRoomView.unityViewNode
        JoinRoomView.win = win

        --初始化View
        JoinRoomView:initAllView()

        -- 由于win隐藏，而不是销毁，隐藏后和GRoot脱离了关系，因此需要
        -- 特殊销毁
        _ENV.thisMod:RegisterCleanup(
            function()
                win:Dispose()
            end
        )
    end

    JoinRoomView.roomNumber = ""

    JoinRoomView.win:Show()

end

function JoinRoomView:initAllView()

    local clostBtn = self.unityViewNode:GetChild("closeBtn")
    clostBtn.onClick:Set(
        function()
            self:destroy()
        end
    )

    local resetBtn = self.unityViewNode:GetChild("buttonCS")
    resetBtn.onClick:Set(
        function()
            self:onResetBtnClick()
        end
    )

    local backBtn = self.unityViewNode:GetChild("buttonSC")
    backBtn.onClick:Set(
        function()
            self:onBackBtnClick()
        end
    )

    for i = 0, 9 do
        local button = self.unityViewNode:GetChild("button" .. tostring(i))
        button.onClick:Set(
            function()
                self:onInputButton(i)
            end
        )

    end

    self.numbers = {}
    for i = 1, 6 do
        local num = self.unityViewNode:GetChild("number"..i)
        self.numbers[i] = num
    end

    self.hintText = self.unityViewNode:GetChild("hintText")

end

function JoinRoomView:onResetBtnClick()
    for i = 1, 6 do
        self.numbers[i].text = ""
    end

    self.roomNumber = ""
    self.hintText.visible = true
end

function JoinRoomView:onBackBtnClick()
    local len = string.len(self.roomNumber)

    if len ~= 0 then
        self.numbers[len].text = ""
    end

    self.roomNumber = string.sub(self.roomNumber,0,len - 1)

    if self.roomNumber == "" then
        self.hintText.visible = true
    else
        self.hintText.visible = false
    end
end

function JoinRoomView:onInputButton(number)
    local numberLength = 0
    if self.roomNumber then
        numberLength = string.len(self.roomNumber)
    end

    if numberLength < 6 then
        local strIndex = numberLength + 1
        local num = self.numbers[strIndex]
        if num ~= nil then
            num.text = tostring(number)
        else
            logger.error("JoinRoomView:onInputButton, index "..strIndex.." out of range")
        end

        if self.roomNumber then
            self.roomNumber= self.roomNumber .. tostring(number)
        else
            self.roomNumber=  tostring(number)
        end

        if self.roomNumber == "" then
            self.hintText.visible = true
        else
            self.hintText.visible = false
        end
    end

    self:joinRoomCheck(self.roomNumber)
end

function JoinRoomView:joinRoomCheck(str)
    if #str == 6 then
        self:requetJoinRoom(str)
    end
end

function JoinRoomView:enterGame(roomInfo)
    local mylobbyView = fairy.GRoot.inst:GetChildAt(0)
    fairy.GRoot.inst:RemoveChild(mylobbyView)
    fairy.GRoot.inst:CleanupChildren()

    local parameters = {
        gameType = "4",
        roomInfo = roomInfo
    }

    local rapidJson = require("rapidjson")
    local jsonString = rapidJson.encode(parameters)
    local roomConfig = rapidJson.decode(roomInfo.config)
    _ENV.thisMod:LaunchGameModule(roomConfig.modName, jsonString)

    self:destroy()
end

function JoinRoomView:checkUpdate(roomInfo)
    if roomInfo.moduleCfg == "" then
        self:enterGame(roomInfo)
    else
        local rapidJson = require("rapidjson")
        local moduleCfg = rapidJson.decode(roomInfo.moduleCfg)
        local roomConfig = rapidJson.decode(roomInfo.config)

        if moduleCfg.name ~= roomConfig.modName then
            logger.error("moduleCfg name:"..moduleCfg.name..", no equa roomConfig modName:".. roomConfig.modName)
            return
        end

        -- 客户端只做模块版本检查，服务器已经做了C#版本、大厅版本、条件检查
        local modVersionStr = CS.NetHelper.GetModVersion(roomConfig.modName)
        local icmp = CS.NetHelper.VersionCompare(moduleCfg.version, modVersionStr)
        if icmp > 0 then
            local upgradeComplete = function(err)
                if err == nil then
                    self:enterGame(roomInfo)
                else
                    dialog.showDialog(err.msg, function() end)
                end
            end

            logger.trace("JoinRoomView:checkUpdate, do upgrade:"..moduleCfg.name)
            local progress = updateProgress:new(moduleCfg.name, upgradeComplete)
            progress:updateView()
        else
            self:enterGame(roomInfo)
        end
    end
end

function JoinRoomView:constructQueryString()
    local lobbyVersion = require "lobby/version"
	local qs = "qMod="
	qs = qs .. "&modV="
	qs = qs .. "&csVer=" .. urlEncoder.encode(CS.Version.VER_STR) -- csharp core version
	qs = qs .. "&lobbyVer=" .. urlEncoder.encode(lobbyVersion.VER_STR) -- lobby version
	qs = qs .. "&operatingSystem=" .. urlEncoder.encode(CS.UnityEngine.SystemInfo.operatingSystem) -- system name
	qs = qs .. "&operatingSystemFamily=" .. urlEncoder.encode(CS.UnityEngine.SystemInfo.operatingSystemFamily:ToString())
	-- system family
	qs = qs .. "&deviceUniqueIdentifier=" .. urlEncoder.encode(CS.UnityEngine.SystemInfo.deviceUniqueIdentifier)
	-- mobile device id
	qs = qs .. "&deviceName=" .. urlEncoder.encode(CS.UnityEngine.SystemInfo.deviceName) -- device name
	qs = qs .. "&deviceModel=" .. urlEncoder.encode(CS.UnityEngine.SystemInfo.deviceModel) -- device mode
    qs = qs .. "&network=" .. urlEncoder.encode(CS.NetHelper.NetworkTypeString()) -- device network type
    qs = qs .. "&forceUpgrade="..urlEncoder.encode(tostring(lenv.forceUseUpgrade)) -- if force upgrade
    qs = qs .. "&tk=".. urlEncoder.encode(CS.UnityEngine.PlayerPrefs.GetString("token", ""))  -- tk
	return qs
end

function JoinRoomView:requetJoinRoom(roomNumber)
        local queryString = self:constructQueryString()
        local url = urlpathsCfg.rootURL .. urlpathsCfg.requestRoomInfo .. "?"..queryString
        local requestRoomInfo = {
            roomNumber = roomNumber
        }

        local body = proto.encodeMessage("lobby.MsgRequestRoomInfo", requestRoomInfo)
        httpHelper.post(
            self.unityViewNode,
            url,
            body,
            function(req, resp)
                if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
                    local requestRoomInfoRsp = proto.decodeMessage("lobby.MsgRequestRoomInfoRsp", resp.Data)
                    logger.debug("requestRoomInfoRsp--------: ", requestRoomInfoRsp)
                    if requestRoomInfoRsp.result == proto.lobby.MsgError.ErrSuccess then
                        self:checkUpdate(requestRoomInfoRsp.roomInfo)
                    else
                        local errMsg = lobbyError[requestRoomInfoRsp.result]
                        logger.debug("errMsg:"..errMsg)
                        if errMsg ~= nil then
                           dialog.showDialog(errMsg,
                             function()
                             end
                           )
                        end
                    end
                else
                    logger.debug("requetJoinRoom error : ", req.State)
                end
            end
        )
end

function JoinRoomView:destroy()
    self.win:Hide()
    self.win:Dispose()
    self.unityViewNode = nil
    self.win = nil
end

return JoinRoomView