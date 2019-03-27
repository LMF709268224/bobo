--[[
    牌的图片挂载
]]
local Mounter = {}
Mounter.VERSION = "1.0"
local dfPath = "GuanZhang/Script/"
local AgariIndex = require(dfPath .. "dfMahjong/AgariIndex")
local TileImageMap = require(dfPath .. "dfMahjong/tileImageMap")
local Loader = require(dfPath .. "dfMahjong/spriteLoader")
local dfCompatibleAPI = require(dfPath .. "dfMahjong/dfCompatibleAPI")
-----------------------------------------------
--为手牌或者花牌挂上牌的图片
-----------------------------------------------
function Mounter:mountTileImage(btn, tileID)
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
	pathDianShu = huaSe_path..tostring(dianShu)

	if dianShu > 10 and dianShu < 14 then
		pathHuaSeBig = string.format(huaSeABC_path, tostring(dianShu))
    else
		--大小鬼 15
		--A 14
		if dianShu == 14 then
			pathDianShu = huaSe_path.."1"
		end
    end
    hImg.sprite = dfCompatibleAPI:loadDynPic("tiles/" .. pathDianShu)
    hImghuasbig.sprite = dfCompatibleAPI:loadDynPic("tiles/" .. pathHuaSeBig)
    hImghuasmall.sprite = dfCompatibleAPI:loadDynPic("tiles/" .. pathHuaSe)
	hImghuasbig:SetNativeSize()
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
