--luacheck:no self

local NewRoomView = {}

local fairy = require "lobby/lcore/fairygui"
local logger = require "lobby/lcore/logger"
local urlpathsCfg = require "lobby/lcore/urlpathsCfg"
local httpHelper = require "lobby/lcore/httpHelper"
local proto = require "lobby/scripts/proto/proto"
local rapidJson = require("rapidjson")
local CS = _ENV.CS

function NewRoomView.new()
    if NewRoomView.unityViewNode then
        logger.debug("CreateRoomView ---------------------")
    else
        _ENV.thisMod:AddUIPackage("lobby/fui_create_room/lobby_create_room")
        local viewObj = _ENV.thisMod:CreateUIObject("lobby_create_room", "createRoom")

        NewRoomView.unityViewNode = viewObj

        local win = fairy.Window()
        win.contentPane = NewRoomView.unityViewNode
        NewRoomView.win = win

        --初始化View
        NewRoomView:initAllView()

        -- 由于win隐藏，而不是销毁，隐藏后和GRoot脱离了关系，因此需要
        -- 特殊销毁
        _ENV.thisMod:RegisterCleanup(
            function()
                win:Dispose()
            end
        )
    end

    local clostBtn = NewRoomView.unityViewNode:GetChild("n51")
    clostBtn.onClick:Set(
        function()
            NewRoomView:destroy()
        end
    )

    NewRoomView.win:Show()
end

function NewRoomView:initAllView()
    local gzRuleView = NewRoomView.unityViewNode:GetChild("n49")
    local runFastRuleView = require "lobby/scripts/newRoom/runFastRuleView"
    runFastRuleView.bindView(gzRuleView, self)

    -- local viewObj = NewRoomView.unityViewNode:GetChild("n50")
    -- local dfRuleView = require "lobby/scripts/newRoom/dfRuleView"
    -- dfRuleView.bindView(viewObj)
end

function NewRoomView:enterGame(roomInfo)
    local mylobbyView = fairy.GRoot.inst:GetChildAt(0)
    fairy.GRoot.inst:RemoveChild(mylobbyView)
    fairy.GRoot.inst:CleanupChildren()

    local parameters = {
        gameType = "4",
        roomInfo = roomInfo
    }

    local jsonString = rapidJson.encode(parameters)
    _ENV.thisMod:LaunchGameModule("game1", jsonString)
end

function NewRoomView:reEnterGame(roomInfo)
    self.enterGame(roomInfo)
end

function NewRoomView:doUpgrade()
    -- TODO: 更新
end

function NewRoomView:createRoom(ruleJsonString)
    logger.debug("createRoom")

    local tk = CS.UnityEngine.PlayerPrefs.GetString("token", "")
    local url = urlpathsCfg.rootURL .. urlpathsCfg.createRoom .. "?tk=" .. tk
    local jsonString = rapidJson.encode(ruleJsonString)
    local createRoomReq = {
        config = jsonString
    }
    local body = proto.encodeMessage("lobby.MsgCreateRoomReq", createRoomReq)
    httpHelper.post(
        self.unityViewNode,
        url,
        body,
        function(req, resp)
            if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
                local createRoomRsp = proto.decodeMessage("lobby.MsgCreateRoomRsp", resp.Data)
                logger.debug("create room ok createRoomRsp--------: ", createRoomRsp)
                if createRoomRsp.Result == proto.MsgError.ErrSuccess then
                    self:enterGame(createRoomRsp.roomInfo)
                elseif createRoomRsp.Result == proto.MsgError.ErrUserInOtherRoom then
                    self:reEnterGame(createRoomRsp.roomInfo)
                elseif createRoomRsp.Result == proto.MsgError.ErrIsNeedUpdate then
                    self:doUpgrade()
                end
            else
                logger.debug("create room error : ", req.State)
            end
        end
    )
end

function NewRoomView:destroy()
    self.win:Hide()
    self.win:Dispose()
    self.unityViewNode = nil
    self.win = nil
end

return NewRoomView
