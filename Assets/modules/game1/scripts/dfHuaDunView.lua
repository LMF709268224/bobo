--[[
    显示一手牌结束后的花牌墩子详情
]]

local DFHuaDunView = {}
local mt = {__index=DFHuaDunView}
local dfPath = "GuanZhang/Script/"
local tileMounter = require ( dfPath .."dfMahjong/tileImageMounter")
local Loader = require ( dfPath .. "dfMahjong/spriteLoader")
local dfCompatibleAPI = require(dfPath ..'dfMahjong/dfCompatibleAPI')

function DFHuaDunView:new(room,players, viewObj)
    local dfHuaDunView = {}
    setmetatable(dfHuaDunView, mt)
	dfHuaDunView.room = room


    --结果是以messagebox来显示
    --dfHuaDunView.unityViewNode = ViewManager.OpenMessageBoxWithOrder(prefabName,5)
    --dfHuaDunView.unityViewNode = room:openMessageBoxFromDaFeng(prefabName,5)
    dfHuaDunView.unityViewNode = viewObj
    dfHuaDunView.players = players

	dfHuaDunView:initView()
	dfHuaDunView:updateView()
    return dfHuaDunView
end

function DFHuaDunView:OnCloseClicked()
	self.unityViewNode:Destroy()
end

-------------------------------------------
--玩家基本信息
-------------------------------------------
function DFHuaDunView:updatePlayerInfoData(player,c)
    --名字
    local name = player.nick
    if name == nil or name == "" then
        name = player.userID
    end
    local isMe = player == self.room:me()
    if isMe then
        c.textName.text =  "<color=#a0fd11>" ..name.. "</color>"
    else
        c.textName.text =  "<color=#61b9e2>" ..name.. "</color>"
    end
    --庄家
    if self.room.bankerChairID == player.chairID then
        c.imageZhuan:SetActive(true)
    end
    --房主
    if player.userID == self.room.ownerID then
        c.imageRoom:SetActive(true)
    end
    --头像
    c.imageIcon.transform:SetActive(true)
    if player.sex == 1 then
        c.imageIcon.sprite = dfCompatibleAPI:loadDynPic("playerIcon/boy_img")
    else
        c.imageIcon.sprite = dfCompatibleAPI:loadDynPic("playerIcon/girl_img")
    end
    if player.headIconURI ~= nil and player.headIconURI ~= "" then
        -- player.playerView:getPartnerWeixinIcon(player.headIconURI,function(texture)
        --     c.imageIcon.transform:SetImage(texture)
        -- end)
        local tool = g_ModuleMgr:GetModule(ModuleName.TOOLLIB_MODULE)
        tool:SetUrlImage(c.imageIcon.transform,player.headIconURI)
    else
        logger.debug("player.headIconURI is nill")
    end
end

-------------------------------------------
--牌组信息
-------------------------------------------
function DFHuaDunView:updatePlayerCardsData(player,c)
    local tilesFlower = player.tilesFlower
    --排序，要以  春夏秋冬，梅兰竹菊，中发白风 这样的顺序排序
    table.sort(tilesFlower, function(x,y)
        if (x >= pokerfaceProto.enumTid_SPRING and y >= pokerfaceProto.enumTid_SPRING)
            or (x >= pokerfaceProto.enumTid_PLUM and y >= pokerfaceProto.enumTid_PLUM and
            x <= pokerfaceProto.enumTid_CHRYSANTHEMUM and y <= pokerfaceProto.enumTid_CHRYSANTHEMUM ) then
            return x < y
        end
        return x > y
    end)
    for i = 1, #tilesFlower do
        local tiles = tilesFlower[i]
        local oCardObj = c.huaCards:Find(tostring(i))
        tileMounter:mountTileImage(oCardObj, tiles)
        oCardObj:SetActive(true)
    end
    local dunNumber = 0
    --杠墩子
    local melds = player.melds --落地牌组
    for _,v in ipairs(melds)do
        local meldType = v.meldType --牌组类型 0:顺子  1:刻子  2:明杠  3:加杠  4:暗杠
        if meldType ~= 0 and meldType ~= 1 then
            local tile1 = v.tile1--第一个牌
            for i = 1,4 do
                dunNumber = dunNumber + 1
                local oCardObj = c.dunZiCards:Find(tostring(dunNumber))
                tileMounter:mountTileImage(oCardObj, tile1)
                oCardObj:SetActive(true)
            end
        end
    end
end

function DFHuaDunView:updateView()
	local number = 1
	for _,player in ipairs(self.players) do
		if player ~= nil then
            local c = self.contentGroup[number]
            --玩家基本信息
            self:updatePlayerInfoData(player,c)
            --牌组信息
            self:updatePlayerCardsData(player,c)
			number = number + 1
		end
	end
end

function DFHuaDunView:initView()
    self.unityViewNode:AddClick("CloseButton", function() self:OnCloseClicked() end)
	local contentGroup = {}
    for var =1 ,4, 1 do
        local contentGroupData = {}
        local group = self.unityViewNode.transform:Find("Content/"..var)
        contentGroupData.group = group
        --头像
        contentGroupData.imageIcon = group:SubGet("ImageIcon", "Image")
        contentGroupData.imageIcon.transform:SetActive(false)
        --庄家标志
        contentGroupData.imageZhuan = group:Find("ImageZhuan")
        contentGroupData.imageZhuan:SetActive(false)
        --房主标志
        contentGroupData.imageRoom = group:Find("ImageRoom")
        contentGroupData.imageRoom:SetActive(false)
        --名字
        contentGroupData.textName = group:SubGet("TextName", "Text")
        --花牌详情
        contentGroupData.huaCards = group:Find("HuaCards")
        --墩子详情
        contentGroupData.dunZiCards = group:Find("DunZiCards")
        --保存userID
        contentGroupData.userID = ""
        contentGroup[var] = contentGroupData

        --group:SetActive(false)
    end
    self.contentGroup = contentGroup
end

return DFHuaDunView