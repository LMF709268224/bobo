--[[
    牌的图片挂载
]]
local Mounter = {}
Mounter.VERSION = "1.0"
local AgariIndex = require("scripts/AgariIndex")
local logger = require "lobby/lcore/logger"
-- local dfPath = "GuanZhang/Script/"
-- local AgariIndex = require(dfPath .. "dfMahjong/AgariIndex")
-- local TileImageMap = require(dfPath .. "dfMahjong/tileImageMap")
-- local Loader = require(dfPath .. "dfMahjong/spriteLoader")
-- local dfCompatibleAPI = require(dfPath .. "dfMahjong/dfCompatibleAPI")
local countMap = {
	-- 点数: 红色 2 - 10 J Q K A 王 15张
	-- 点数: 黑色 2 - 10 J Q K A 王 15张
	["red_2"] = "ui://p966ud2tef8pk",
	["red_3"] = "ui://p966ud2tef8pl",
	["red_4"] = "ui://p966ud2tef8pm",
	["red_5"] = "ui://p966ud2tef8pn",
	["red_6"] = "ui://p966ud2tef8po",
	["red_7"] = "ui://p966ud2tef8pp",
	["red_8"] = "ui://p966ud2tef8pq",
	["red_9"] = "ui://p966ud2tef8pr",
	["red_10"] = "ui://p966ud2tef8ps",
	["red_11"] = "ui://p966ud2tef8pt",
	["red_12"] = "ui://p966ud2tef8pu",
	["red_13"] = "ui://p966ud2tef8pv",
	["red_14"] = "ui://p966ud2tef8pj",
	["red_15"] = "ui://p966ud2tef8p2",
	["black_2"] = "ui://p966ud2tef8p7",
	["black_3"] = "ui://p966ud2tef8p8",
	["black_4"] = "ui://p966ud2tef8p9",
	["black_5"] = "ui://p966ud2tef8pa",
	["black_6"] = "ui://p966ud2tef8pb",
	["black_7"] = "ui://p966ud2tef8pc",
	["black_8"] = "ui://p966ud2tef8pd",
	["black_9"] = "ui://p966ud2tef8pe",
	["black_10"] = "ui://p966ud2tef8pf",
	["black_11"] = "ui://p966ud2tef8pg",
	["black_12"] = "ui://p966ud2tef8ph",
	["black_13"] = "ui://p966ud2tef8pi",
	["black_14"] = "ui://p966ud2tef8p6",
	["black_15"] = "ui://p966ud2tef8p1"
}
local flowerMap = {
	-- 花色: 红桃 方块 梅花 黑桃
	["flower_0"] = "ui://p966ud2tef8py",
	["flower_1"] = "ui://p966ud2tef8p4",
	["flower_2"] = "ui://p966ud2tef8p10",
	["flower_3"] = "ui://p966ud2tef8pw"
}
local bigImageMap = {
	-- 右下角大图:
	["bigImage_0"] = "ui://p966ud2tef8pz", --红桃
	["bigImage_1"] = "ui://p966ud2tef8p5", --方块
	["bigImage_2"] = "ui://p966ud2tef8p11", --梅花
	["bigImage_3"] = "ui://p966ud2tef8px", --黑桃
	-- JQK王
	["bigImage_red_11"] = "ui://p966ud2tef8p1a", --红J
	["bigImage_black_11"] = "ui://p966ud2tef8p17", --黑J
	["bigImage_red_12"] = "ui://p966ud2tef8p1b", --红Q
	["bigImage_black_12"] = "ui://p966ud2tef8p18", --黑Q
	["bigImage_red_13"] = "ui://p966ud2tef8p1c", --红K
	["bigImage_black_13"] = "ui://p966ud2tef8p19", --黑K
	["bigImage_red_15"] = "ui://p966ud2tef8p15", --红王
	["bigImage_black_15"] = "ui://p966ud2tef8p16" --黑王
}
-----------------------------------------------
--为手牌或者花牌挂上牌的图片
-----------------------------------------------
function Mounter:mountTileImageOld(btn, tileID)
	local hImg = btn:SubGet("hua", "Image")
	local hImghuasbig = btn:SubGet("huasbig", "Image")
	local hImghuasmall = btn:SubGet("huasmall", "Image")
	--hImg:SetActive(true)
	local artID = AgariIndex.tileId2ArtId(tileID)
	local dianShu = math.floor(artID / 4) + 2
	local huaSe = artID % 4
	local pathHuaSeBig = ""
	local pathHuaSe = ""
	local pathDianShu = ""

	local huaSe_path = "suit_hong_"
	local huaSeABC_path = "suit_honghua_%s_big"
	if huaSe == 1 then
		pathHuaSeBig = "suit_fk_big"
		pathHuaSe = "suit_fk"
	elseif huaSe == 2 then
		pathHuaSeBig = "suit_mh_big"
		pathHuaSe = "suit_mh"
		huaSe_path = "suit_hei_"
		huaSeABC_path = "suit_heihua_%s_big"
	elseif huaSe == 0 then
		pathHuaSeBig = "suit_hx_big"
		pathHuaSe = "suit_hx"
	else
		pathHuaSeBig = "suit_ht_big"
		pathHuaSe = "suit_ht"
		huaSe_path = "suit_hei_"
		huaSeABC_path = "suit_heihua_%s_big"
	end
	pathDianShu = huaSe_path .. tostring(dianShu)

	if dianShu > 10 and dianShu < 14 then
		pathHuaSeBig = string.format(huaSeABC_path, tostring(dianShu))
	else
		--大小鬼 15
		--A 14
		if dianShu == 14 then
			pathDianShu = huaSe_path .. "1"
		end
	end
	hImg.sprite = dfCompatibleAPI:loadDynPic("tiles/" .. pathDianShu)
	hImghuasbig.sprite = dfCompatibleAPI:loadDynPic("tiles/" .. pathHuaSeBig)
	hImghuasmall.sprite = dfCompatibleAPI:loadDynPic("tiles/" .. pathHuaSe)
	hImghuasbig:SetNativeSize()
end

function Mounter:mountTileImage(btn, tileID)
	local artID = AgariIndex.tileId2ArtId(tileID)
	local dianShu = math.floor(artID / 4) + 2
	local huaSe = artID % 4

	local num = btn:GetChild("n1")
	num.visible = false
	local flag = btn:GetChild("n2")
	flag.visible = false
	local big = btn:GetChild("n3")
	big.visible = false
	local position = nil

	local pathHuaSeBig = "bigImage_" .. tostring(huaSe)
	local pathHuaSeBig_2 = "bigImage_"
	local pathHuaSe = "flower_" .. tostring(huaSe)
	local pathDianShu = ""
	if huaSe == 1 or huaSe == 0 then
		-- 方块 红桃
		pathDianShu = "red_"
	else
		-- 梅花 黑桃
		pathDianShu = "black_"
	end
	pathHuaSeBig_2 = pathHuaSeBig_2 .. pathDianShu .. tostring(dianShu)
	pathDianShu = pathDianShu .. tostring(dianShu)

	if dianShu > 10 and dianShu < 14 then
		--JQK
		pathHuaSeBig = pathHuaSeBig_2
		position = btn:GetChild("p2")
	elseif dianShu == 15 then
		--大小鬼 15
		pathHuaSe = ""
		pathHuaSeBig = pathHuaSeBig_2
		position = btn:GetChild("p2")
	else
		--A 14
		position = btn:GetChild("p1")
	end

	num.url = countMap[pathDianShu]
	num.visible = true
	if pathHuaSe ~= "" then
		flag.url = flowerMap[pathHuaSe]
		flag.visible = true
	end
	-- big.position = position
	-- logger.error("big.position : ", big.position)
	big.url = bigImageMap[pathHuaSeBig]
	big.visible = true
end

--组牌显示
function Mounter:mountMeldEnableImage(btn, tileID, viewChairID)
	local tileData = TileImageMap[viewChairID].melds
	local hImg = btn:Find("hua")
	hImg:SetActive(true)

	local skin = btn:GetComponent("SkinBehaviour")
	skin:ReplaceSkin(tileData.bg_show)

	self:mountTileImage(btn, tileID)
end

--组牌隐藏
function Mounter:mountMeldDisableImage(btn, tileID, viewChairID)
	local tileData = TileImageMap[viewChairID].melds

	local hImg = btn:Find("hua")
	hImg:SetActive(false)

	local skin = btn:GetComponent("SkinBehaviour")
	skin:ReplaceSkin(tileData.bg_hide)
end

return Mounter
