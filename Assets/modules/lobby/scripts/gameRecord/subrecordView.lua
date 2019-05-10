--[[
    游戏子记录界面
]]
--luacheck:no self
local SubrecordView = {}

local logger = require "lobby/lcore/logger"
local dialog = require "lobby/lcore/dialog"
local rapidJson = require("rapidjson")

function SubrecordView.new(replayRooms, lobbyView)
    if SubrecordView.unityViewNode then
        logger.debug("SubrecordView ---------------------")
    else
        _ENV.thisMod:AddUIPackage("lobby/fui_game_record/lobby_game_record")
        local viewObj = _ENV.thisMod:CreateUIObject("lobby_game_record", "subRecordView")

        -- 播放战绩后退回大厅，需要保存战绩页面，将此页面加到大厅页面下面
        SubrecordView.unityViewNode = viewObj
        lobbyView.viewNode:AddChild(SubrecordView.unityViewNode)
        SubrecordView.lobbyView = lobbyView

        _ENV.thisMod:RegisterCleanup(
            function()
                viewObj:Dispose()
            end
        )
    end

    --保存记录
    SubrecordView.replayRooms = replayRooms

    -- 初始界面
    SubrecordView:initAllView()
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

-- render item
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
            self:enterReplayRoom(record)
        end
    )
end

function SubrecordView:enterReplayRoom(record)
    local recordCfg = SubrecordView.replayRooms
    local modName
    if recordCfg.recordRoomType == 1 then
        -- 大丰麻将
        modName = "game2"
    elseif recordCfg.recordRoomType == 8 then
        -- 关张
        modName = "game1"
    end

    -- 不支持未知游戏
    if modName == nil then
        local msg = "未知游戏, roomType  = " .. recordCfg.recordRoomType
        dialog.showDialog(
            msg,
            function()
            end
        )
        return
    end

    local parameters = {
        -- 回拨入口
        gameType = "3",
        -- 回拨ID
        rid = record.recordUUID
    }
    local jsonString = rapidJson.encode(parameters)
    self.lobbyView:enterRoom(modName, jsonString)
end

-- 将本身节点从大厅移除
function SubrecordView:destroy()
    self.lobbyView.viewNode:RemoveChild(self.unityViewNode)
    self.unityViewNode:Dispose()
    self.unityViewNode = nil
end

return SubrecordView
