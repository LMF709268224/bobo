--[[
    RecordTotalView 战绩界面
]]
--luacheck: no self
local RecordTotalView = {}
local logger = require "lobby/lcore/logger"
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

    -- RecordTotalView:loadData()
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
-- 更新短语列表
function RecordTotalView:updateList()
    self.dataMap = {}
    self.list.onClickItem:Add(
        function(onClickItem)
            self:sendMsg(onClickItem.data:GetChild("n0").text)
        end
    )

    self.list.numItems = #self.dataMap
end
function RecordTotalView:renderPhraseListItem(index, obj)
    local msg = self.dataMap[index + 1]
    local t = obj:GetChild("n0")
    t.text = msg
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
    local url = urlpathsCfg.rootURL .. urlpathsCfg.lrproom .. "?tk=" .. tk
    httpHelper.get(
        self.viewNode,
        url,
        function(req, resp)
            if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
                -- self:enterGame(createRoomRsp.roomInfo.gameServerID, createRoomRsp.roomInfo)
                local createRoomRsp = proto.decodeMessage("lobby.MsgAccLoadReplayRoomsReply", resp.Data)
                logger.debug("+++++++++++++++++++++++--------: ", createRoomRsp)

                --初始化数据
                self:updateList()
            else
                errHelper.dumpHttpReqError(req)
            end

            req:Dispose()
        end
    )
end

return RecordTotalView
