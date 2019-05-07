--[[
    牌的图片挂载
]]
--luacheck: no self
local Mounter = {}
-- local logger = require "lobby/lcore/logger"
local AgariIndex = require("scripts/AgariIndex")

function Mounter:mountTileImage(btn, tileID)
	local artID = AgariIndex.tileId2ArtId(tileID)
	local m = "ui://lobby_mahjong/suit" .. artID
	local num = btn:GetChild("title")
	num.url = m
end

--组牌显示
function Mounter:mountMeldEnableImage(btn, tileID, _)
	-- local tileData = TileImageMap[viewChairID].melds
	-- local hImg = btn:Find("hua")
	-- hImg:SetActive(true)

	-- local skin = btn:GetComponent("SkinBehaviour")
	-- skin:ReplaceSkin(tileData.bg_show)

	self:mountTileImage(btn, tileID)
end

return Mounter
