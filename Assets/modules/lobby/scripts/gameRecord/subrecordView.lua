--[[
    游戏子记录界面
]]
local SubrecordView = {}

local fairy = require "lobby/lcore/fairygui"
local logger = require "lobby/lcore/logger"
local urlpathsCfg = require "lobby/lcore/urlpathsCfg"
local httpHelper = require "lobby/lcore/httpHelper"
local errHelper = require "lobby/lcore/lobbyErrHelper"
local proto = require "lobby/scripts/proto/proto"
local dialog = require "lobby/lcore/dialog"
local rapidJson = require("rapidjson")
local CS = _ENV.CS

function SubrecordView.new(replayRooms)
    if SubrecordView.unityViewNode then
        logger.debug("SubrecordView ---------------------")
    else
        _ENV.thisMod:AddUIPackage("lobby/fui_game_record/lobby_game_record")
        local viewObj = _ENV.thisMod:CreateUIObject("lobby_game_record", "subRecordView")

        SubrecordView.unityViewNode = viewObj

        local win = fairy.Window()
        win.contentPane = SubrecordView.unityViewNode
        SubrecordView.win = win

        -- 由于win隐藏，而不是销毁，隐藏后和GRoot脱离了关系，因此需要
        -- 特殊销毁
        _ENV.thisMod:RegisterCleanup(
            function()
                win:Dispose()
            end
        )
    end

    SubrecordView.replayRooms = replayRooms

    SubrecordView:initAllView()
    SubrecordView.win:Show()
end

function SubrecordView:initAllView()
    -- body
    local clostBtn = self.unityViewNode:GetChild("closeBtn")
    clostBtn.onClick:Set(
        function()
            self:destroy()
        end
    )

    self.list = SubrecordView.unityViewNode:GetChild("list").asList
    self.list.itemRenderer = function(index, obj)
        self:renderPhraseListItem(index, obj)
    end
    self.list:SetVirtual()

    local replayRooms = SubrecordView.replayRooms
    local replayPlayerInfos = replayRooms.players

    local name
    local label
    local userID
    for i = 1, #replayPlayerInfos do
        name = replayPlayerInfos[i].nick
        userID = replayPlayerInfos[i].userID
        label = self.unityViewNode:GetChild("player" .. i)
        if name ~= "" then
            label.text = name
        else
            label.text = userID
        end
    end

    self:updateList()
end

-- 更新列表
function SubrecordView:updateList()
    self.records = {}
    for i, record in ipairs(SubrecordView.replayRooms.records) do
        self.records[i] = record
    end
    self.list.numItems = #self.records
end

function SubrecordView:renderPhraseListItem(index, obj)
    local record = self.records[index + 1]

    local roomNumber = obj:GetChild("roundText")
    roomNumber.text = index + 1
    local date = obj:GetChild("time")
    date.text = os.date("%H:%M", record.startTime * 60)
    local label
    for i = 1, #record.playerScores do
        label = obj:GetChild("score" .. i)
        label.text = record.playerScores[i].score
    end

    local playBtn = obj:GetChild("playBtn")

    playBtn.onClick:Set(
        function()
            self:onLoadReplayRecord(record.recordUUID)
        end
    )
end

function SubrecordView:onLoadReplayRecord(recordUUID)
    -- 拉取战绩
    if SubrecordView.replayLocked then
        dialog.showDialog(
            "上一个请求尚未完成，请稍后再试",
            function()
            end
        )
        return
    end

    SubrecordView.replayLocked = true

    local tk = CS.UnityEngine.PlayerPrefs.GetString("token", "")
    local loadGameRecordUrl =
        urlpathsCfg.rootURL .. urlpathsCfg.lrprecord .. "?&rt=1&tk=" .. tk .. "&rid=" .. recordUUID

    logger.debug("onLoadReplayRecord loadGameRecordUrl:", loadGameRecordUrl)
    -- 加滚动条
    httpHelper.get(
        self.unityViewNode,
        loadGameRecordUrl,
        function(req, resp)
            if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
                local httpError = errHelper.dumpHttpRespError(resp)
                if httpError == nil then
                    if resp.Data then
                        local record = proto.decodeMessage("lobby.MsgAccLoadReplayRecord", resp.Data)
                        self:enterGame(record)
                    --local roomConfig = Json.decode(msgAccLoadReplayRecord.roomJSONConfig)
                    -- 初始化数据

                    --local replayRecordBytes
                    --self:updateList(gameRecords)
                    end
                end
                resp:Dispose()
            else
                local err = errHelper.dumpHttpReqError(req)
                if err then
                    dialog.showDialog(
                        err.msg,
                        function()
                        end
                    )
                end
            end
            req:Dispose()
        end
    )
    self.replayLocked = false
end

function SubrecordView:enterGame(record)
    --logger.debug(" SubrecordView:enterGame record : ", record)
    local mylobbyView = fairy.GRoot.inst:GetChildAt(0)
    fairy.GRoot.inst:RemoveChild(mylobbyView)
    fairy.GRoot.inst:CleanupChildren()

    local parameters = {
        gameType = "3",
        record = record
    }
    local jsonString = rapidJson.encode(parameters)
    --local roomConfig = rapidJson.decode(record.roomJSONConfig)

    _ENV.thisMod:LaunchGameModule("game1", jsonString)

    self:destroy()
end

function SubrecordView:destroy()
    self.win:Hide()
    self.win:Dispose()
    self.unityViewNode = nil
    self.win = nil
end

return SubrecordView
