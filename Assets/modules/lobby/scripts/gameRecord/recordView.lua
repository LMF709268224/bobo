--[[
    游戏记录界面
]]
--luacheck:no self
local RecordView = {}

local fairy = require "lobby/lcore/fairygui"
local logger = require "lobby/lcore/logger"
local urlpathsCfg = require "lobby/lcore/urlpathsCfg"
local httpHelper = require "lobby/lcore/httpHelper"
local proto = require "lobby/scripts/proto/proto"
local dialog = require "lobby/lcore/dialog"
local errHelper = require "lobby/lcore/lobbyErrHelper"

local subrecordView = require "lobby/scripts/gameRecord/subrecordView"
local CS = _ENV.CS

function RecordView.new()
    if RecordView.unityViewNode then
        logger.debug("RecordView ---------------------")
    else
        _ENV.thisMod:AddUIPackage("lobby/fui_game_record/lobby_game_record")
        local viewObj = _ENV.thisMod:CreateUIObject("lobby_game_record", "recordView")

        RecordView.unityViewNode = viewObj

        local win = fairy.Window()
        win.contentPane = RecordView.unityViewNode
        RecordView.win = win

        -- 由于win隐藏，而不是销毁，隐藏后和GRoot脱离了关系，因此需要
        -- 特殊销毁
        _ENV.thisMod:RegisterCleanup(
            function()
                win:Dispose()
            end
        )
    end

    RecordView:initAllView()

    RecordView.win:Show()
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
    self.dataMap = {}
    for i, replayRoom in ipairs(createRoomRsp.replayRooms) do
        local r = proto.decodeMessage("lobby.MsgReplayRoom", replayRoom.replayRoomBytes)
        self.dataMap[i] = r
    end
    -- self.list.onClickItem:Add(
    --     function(onClickItem)
    --         logger.debug("on game record item click", onClickItem.data:GetChild("roomNumber").text)
    --         logger.debug("on game record item click", self.list:GetChildIndex())
    --     end
    -- )

    self.list.numItems = #self.dataMap
end

function RecordView:goSubrecordView(replayRoom)
    subrecordView.new(replayRoom)
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
        -- logger.debug("replayRoom.players ---------------- : ", playerInfo)
        -- local player = obj:GetChild("player" .. i)
        -- local name = player:GetChild("name")
        -- name.text = playerInfo.nick
        -- local winScore = player:GetChild("winScore")
        -- local loseScore = player:GetChild("loseScore")
        -- winScore.visible = false
        -- loseScore.visible = false

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
    httpHelper.get(
        self.unityViewNode,
        loadGameRecordUrl,
        function(req, resp)
            if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
                local httpError = errHelper.dumpHttpRespError(resp)
                if httpError == nil then
                    if resp.Data then
                        local gameRecords = proto.decodeMessage("lobby.MsgAccLoadReplayRoomsReply", resp.Data)
                        --logger.debug("+++++++++++++++++++++++--------: ", gameRecords)
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

function RecordView:destroy()
    self.win:Hide()
    self.win:Dispose()
    self.unityViewNode = nil
    self.win = nil
end

return RecordView
