--[[
    PlayerInfoView 玩家信息界面
]]
local PlayerInfoView = {}
local logger = require "lobby/lcore/logger"
local fairy = require "lobby/lcore/fairygui"

function PlayerInfoView.showUserInfoView(playerInfo, pos, isOther, room)
    if PlayerInfoView.viewNode then
        logger.debug("showUserInfoView -----------")
    else
        logger.debug("showUserInfoView viewNode is nil.")
        _ENV.thisMod:AddUIPackage("lobby/fui_player_info/lobby_player_info")
        local view = _ENV.thisMod:CreateUIObject("lobby_player_info", "player_info_view")

        PlayerInfoView.viewNode = view
        PlayerInfoView:initView()

        _ENV.thisMod:RegisterCleanup(
            function()
                view:Dispose()
            end
        )
        _ENV.thisMod:SetMsgListener(
            "lobby_chat",
            function(str)
                logger.debug("SetMsgListener : ", str)
                PlayerInfoView:addMsg(str)
            end
        )
    end
    PlayerInfoView.room = room
    PlayerInfoView.playerInfo = playerInfo
    PlayerInfoView.isOther = isOther
    PlayerInfoView:updateView()

    fairy.GRoot.inst:ShowPopup(PlayerInfoView.viewNode)
    PlayerInfoView.viewNode:SetXY(pos.x, pos.y)
end

function PlayerInfoView:updateView()
    self.kickoutBtn.visible = self.isOther
    self:updatePropList()
    -- info
    local sex = "y_nv"
    if self.playerInfo.sex == 1 then
        sex = "y_nan"
    end
    self.sexImage.url = "ui://lobby_player_info/" .. sex
    self.nameText.text = self.playerInfo.nick
    self.idText.text = "ID:" .. self.playerInfo.userID
    self.ipText.text = "IP:" .. self.playerInfo.ip
    self.addressText.text = "地址:" .. self.playerInfo.location
    self.xinNumText.text = self.playerInfo.charm
    self.zuanNumText.text = self.playerInfo.diamond
    self.numberText.text = ""
end

function PlayerInfoView:initView()
    -- info
    self.nameText = self.viewNode:GetChild("name")
    self.idText = self.viewNode:GetChild("id")
    self.ipText = self.viewNode:GetChild("ip")
    self.addressText = self.viewNode:GetChild("address")
    self.numberText = self.viewNode:GetChild("number")
    self.xinNumText = self.viewNode:GetChild("xinNum")
    self.zuanNumText = self.viewNode:GetChild("zuanNum")
    self.sexImage = self.viewNode:GetChild("sex")
    -- button
    self.kickoutBtn = self.viewNode:GetChild("kickoutBtn")
    self.kickoutBtn.onClick:Set(
        function()
        end
    )
    -- list
    self.propList = self.viewNode:GetChild("list").asList
    self.propList.itemRenderer = function(index, obj)
        self:renderPropListItem(index, obj)
    end
    self.propList.onClickItem:Add(
        function(onClickItem)
            self.room:sendDonate(onClickItem.data.name)
        end
    )
    self.propList:SetVirtual()
end

function PlayerInfoView:updatePropList()
    self.dataList = {}
    if self.isOther then
        local images = {"dj_bb", "dj_jd", "dj_qj", "dj_tuoxie", "dj_ganbei", "dj_hj", "dj_meigui", "dj_mmd"}
        local ids = {6, 3, 5, 4, 2, 7, 1, 8}
        for i = 1, 8 do
            local data = {}
            data.image = images[i]
            data.num = i - 4
            data.id = ids[i]
            table.insert(self.dataList, data)
        end
    end
    local num = #self.dataList
    self.propList.numItems = num
    self.propList:ResizeToFit(num)
end

function PlayerInfoView:renderPropListItem(index, obj)
    local data = self.dataList[index + 1]
    local icon = obj:GetChild("icon")
    local xinNum = obj:GetChild("xinNum")
    local zuanNum = obj:GetChild("zuanNum")
    obj.name = data.id
    xinNum.text = data.num * 2
    zuanNum.text = data.num
    icon.url = "ui://lobby_player_info/" .. data.image
end

return PlayerInfoView
