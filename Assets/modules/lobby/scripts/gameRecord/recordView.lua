--[[
    游戏记录界面
]]
--luacheck:no self
local RecordView = {}

--local fairy = require "lobby/lcore/fairygui"
local logger = require "lobby/lcore/logger"
local urlpathsCfg = require "lobby/lcore/urlpathsCfg"
local httpHelper = require "lobby/lcore/httpHelper"
local proto = require "lobby/scripts/proto/proto"
local dialog = require "lobby/lcore/dialog"
local errHelper = require "lobby/lcore/lobbyErrHelper"

local subrecordView = require "lobby/scripts/gameRecord/subrecordView"
local CS = _ENV.CS

function RecordView.new(lobbyView)
    if RecordView.unityViewNode then
        logger.debug("RecordView ---------------------")
    else
        _ENV.thisMod:AddUIPackage("lobby/fui_game_record/lobby_game_record")
        local viewObj = _ENV.thisMod:CreateUIObject("lobby_game_record", "recordView")

        RecordView.unityViewNode = viewObj
        lobbyView.viewNode:AddChild(RecordView.unityViewNode)
        RecordView.lobbyView = lobbyView

        _ENV.thisMod:RegisterCleanup(
            function()
                viewObj:Dispose()
            end
        )
    end

    RecordView:initAllView()
end

function RecordView:initAllView()
    -- body
    local clostBtn = self.unityViewNode:GetChild("closeBtn")
    clostBtn.onClick:Set(
        function()
            self:destroy()
        end
    )

    self.list = RecordView.unityViewNode:GetChild("list").asList
    self.list.itemRenderer = function(index, obj)
        self:renderPhraseListItem(index, obj)
    end
    self.list:SetVirtual()
    self:loadGameRecord()
end

-- 更新列表
function RecordView:updateList(createRoomRsp)
    logger.debug("createRoomRsp = ", createRoomRsp)
    self.dataMap = {}
    for i, replayRoom in ipairs(createRoomRsp.replayRooms) do
        local r = proto.decodeMessage("lobby.MsgReplayRoom", replayRoom.replayRoomBytes)
        self.dataMap[i] = r
    end
    self.list.numItems = #self.dataMap
end

function RecordView:goSubrecordView(replayRoom)
    subrecordView.new(replayRoom, RecordView.lobbyView)
end

function RecordView:renderPhraseListItem(index, obj)
    local replayRoom = self.dataMap[index + 1]

    obj.onClick:Set(
        function()
            self:goSubrecordView(replayRoom)
        end
    )

    local ruleLableText
    if replayRoom.recordRoomType == 1 then
        ruleLableText = "麻将"
    elseif replayRoom.recordRoomType == 3 then
        ruleLableText = "东台麻将"
    elseif replayRoom.recordRoomType == 8 then
        ruleLableText = "关张"
    elseif replayRoom.recordRoomType == 9 then
        ruleLableText = "7王523"
    elseif replayRoom.recordRoomType == 11 then
        ruleLableText = "斗地主"
    else
        ruleLableText = "未知麻将"
    end

    local gameName = obj:GetChild("name")

    gameName.text = ruleLableText

    local roomNumber = obj:GetChild("roomNumber")
    roomNumber.text = replayRoom.roomNumber
    local date = obj:GetChild("time")
    date.text = os.date("%Y-%m-%d %H:%M", replayRoom.startTime * 60)

    local userID = CS.UnityEngine.PlayerPrefs.GetString("userID", "")

    local resultText = obj:GetChild("result")
    local ownerText = obj:GetChild("owner")

    local ownerUserID = replayRoom.ownerUserID

    local owner
    for _, playerInfo in ipairs(replayRoom.players) do
        if playerInfo.userID == ownerUserID then
            if playerInfo.nick ~= "" then
                owner = playerInfo.nick
            else
                owner = playerInfo.userID
            end
            ownerText.text = owner
        end

        if playerInfo.userID == userID then
            if playerInfo.totalScore < 0 then
                --resultText.text = string.format("<color=##CC0000>%s</color>", "Win")
                resultText.text = string.format("Win")
            else
                --resultText.text = string.format("<color=#33FF00>%s</color>", "Lose")
                resultText.text = string.format("Lose")
            end
        end
    end
end

function RecordView:loadGameRecord()
    -- 拉取战绩
    local tk = CS.UnityEngine.PlayerPrefs.GetString("token", "")
    local loadGameRecordUrl = urlpathsCfg.rootURL .. urlpathsCfg.lrproom .. "?&rt=1&tk=" .. tk
    logger.debug("loadGameRecord loadGameRecordUrl:", loadGameRecordUrl)
    -- 加滚动条
    dialog.showDialog("正在加载战绩......")
    local win = dialog.win
    httpHelper.get(
        win,
        loadGameRecordUrl,
        function(req, resp)
            win:Hide()
            if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
                local httpError = errHelper.dumpHttpRespError(resp)
                if httpError == nil then
                    if resp.Data then
                        local gameRecords = proto.decodeMessage("lobby.MsgAccLoadReplayRoomsReply", resp.Data)
                        -- 初始化数据
                        self:updateList(gameRecords)
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
end

-- 将本身节点从大厅移除
function RecordView:destroy()
    self.lobbyView.viewNode:RemoveChild(self.unityViewNode)
    self.unityViewNode:Dispose()
    self.unityViewNode = nil
end

return RecordView
