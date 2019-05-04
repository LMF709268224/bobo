--[[
    RecordTotalView 战绩界面
]]
--luacheck: no self
local RecordTotalView = {}
local fairy = require "lobby/lcore/fairygui"
local urlpathsCfg = require "lobby/lcore/urlpathsCfg"
local httpHelper = require "lobby/lcore/httpHelper"
local proto = require "lobby/scripts/proto/proto"
local errHelper = require "lobby/lcore/lobbyErrHelper"
local CS = _ENV.CS

function RecordTotalView.showView()
    _ENV.thisMod:AddUIPackage("fgui/runfast")
    local view = _ENV.thisMod:CreateUIObject("runfast", "record_total")

    local win = fairy.Window()
    win.contentPane = view
    win.modal = true

    RecordTotalView.viewNode = view
    RecordTotalView.win = win

    RecordTotalView:initView()

    RecordTotalView.win:Show()

    RecordTotalView:loadData()
end

function RecordTotalView:initView()
    self.backBtn = self.viewNode:GetChild("backBtn")
    self.shareRecordBtn = self.viewNode:GetChild("shareRecordBtn")

    self.backBtn.onClick:Set(
        function()
        end
    )
    self.shareRecordBtn.onClick:Set(
        function()
        end
    )

    self.list = self.viewNode:GetChild("list").asList
    self.list.itemRenderer = function(index, obj)
        self:renderPhraseListItem(index, obj)
    end
    self.list:SetVirtual()
end
-- 更新列表
function RecordTotalView:updateList(createRoomRsp)
    self.dataMap = {}
    for i, replayRoom in ipairs(createRoomRsp.replayRooms) do
        local r = proto.decodeMessage("lobby.MsgReplayRoom", replayRoom.replayRoomBytes)
        self.dataMap[i] = r
    end
    self.list.onClickItem:Add(
        function(onClickItem)
            self:sendMsg(onClickItem.data:GetChild("n0").text)
        end
    )

    self.list.numItems = #self.dataMap
end

function RecordTotalView:renderPhraseListItem(index, obj)
    local replayRoom = self.dataMap[index + 1]

    local roomNumber = obj:GetChild("roomNumber")
    roomNumber.text = replayRoom.roomNumber .. "号 房间"
    local gameName = obj:GetChild("gameName")
    gameName.text = ""
    local date = obj:GetChild("date")
    date.text = os.date("%Y-%m-%d %H:%M", replayRoom.startTime * 60)
    for i, playerInfo in ipairs(replayRoom.players) do
        -- logger.debug("replayRoom.players ---------------- : ", playerInfo)
        local player = obj:GetChild("player" .. i)
        local name = player:GetChild("name")
        name.text = playerInfo.nick
        local winScore = player:GetChild("winScore")
        local loseScore = player:GetChild("loseScore")
        winScore.visible = false
        loseScore.visible = false
        if playerInfo.totalScore < 0 then
            loseScore.visible = true
            loseScore.text = playerInfo.totalScore
        else
            winScore.visible = true
            winScore.text = "+" .. playerInfo.totalScore
        end
        local roomOwer = player:GetChild("roomOwer")
        roomOwer.visible = false
    end
end

function RecordTotalView:showLobbyView()
    local lobbyView = require "lobby/scripts/lobbyView"
    lobbyView.show()

    self:destroy()
end

function RecordTotalView:destroy()
    self.win:Hide()
    self.win:Dispose()
    self.viewNode = nil
    self.win = nil
end

function RecordTotalView:loadData()
    local tk = CS.UnityEngine.PlayerPrefs.GetString("token", "")
    local url = urlpathsCfg.rootURL .. urlpathsCfg.lrproom .. "?rt=1&tk=" .. tk
    httpHelper.get(
        self.viewNode,
        url,
        function(req, resp)
            if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
                local httpError = errHelper.dumpHttpRespError(resp)
                if httpError == nil then
                    if resp.Data then
                        local createRoomRsp = proto.decodeMessage("lobby.MsgAccLoadReplayRoomsReply", resp.Data)
                        -- logger.debug("+++++++++++++++++++++++--------: ", createRoomRsp)

                        -- 初始化数据
                        self:updateList(createRoomRsp)
                    end
                end
            else
                errHelper.dumpHttpReqError(req)
            end

            req:Dispose()
        end
    )
end

return RecordTotalView
