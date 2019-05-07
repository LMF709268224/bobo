--[[
    牌的图片挂载
]]
--luacheck: no self
local Mounter = {}
local logger = require "lobby/lcore/logger"

function Mounter:mountTileImage(btn, tileID)
	logger.debug("mountTileImage ---------------- ", tileID)
	local m = "ui://lobby_mahjong/suit" .. tileID
	local num = btn:GetChild("title")
	num.visible = false
	logger.debug(num)
	num.url = m
end

return Mounter
