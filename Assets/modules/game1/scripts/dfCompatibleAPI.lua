-- 所有旧的接口都集中到这里

local DFCompatibleAPI = {}
DFCompatibleAPI.VERSION = "1.0"

DFCompatibleAPI.headImage = {}
-- -- TODO:全局变量，需要去掉
-- require(tmpPath .. "tmp/LuaNotificationCenter")
-- -- TODO:全局变量，需要去掉
-- notificationCenter = LuaNotificationCenter:new()

-- -- TODO:全局变量，需要去掉
-- require (tmpPath .. "tmp/Player")
-- -- TODO:全局变量，需要去掉
-- require (tmpPath .. "tmp/UserData")
-- -- 全局变量，需要去掉
-- List = require "list"

-- -- TODO:全局变量，需要去掉
-- require(tmpPath .. "proto/accessory_pb")
-- -- TODO:全局变量，需要去掉
local tmpPath = "GuanZhang.Script."
require(tmpPath .. "Proto.game_pokerface_split2_pb")
pkproto2 = game_pokerface_split2_pb
-- -- TODO:全局变量，需要去掉
-- pkproto2  = game_mahjong_split2_pb
-- -- TODO:全局变量，需要去掉
require(tmpPath .. "Proto.game_pokerface_s2s_pb")
pokerfaceS2s = game_pokerface_s2s_pb

require(tmpPath .. "Proto.game_pokerface_pb")
pokerfaceProto = game_pokerface_pb

function DFCompatibleAPI:showTip(str, second, timeOutFunc)
    return g_commonModule:ShowTip(str, second, timeOutFunc)
end

function DFCompatibleAPI:showWaitTip(str, second, timeOutFunc, delayTime)
    return g_commonModule:ShowWaitTip(str, second, timeOutFunc, delayTime)
end

function DFCompatibleAPI:closeWaitTip()
    g_commonModule:CloseWaitTip()
end

-- 显示对话框
function DFCompatibleAPI:showMessageBox(str, okFunc, noFunc)
    local dialog = {
        content = str,
        ignoreCloseBtn = true,
        btnData = {
            {callback = okFunc},
            {callback = noFunc}
        }
    }
    return g_commonModule:ShowDialog(dialog)
end

-- 显示对话框
function DFCompatibleAPI:openDialog(str, okFunc, noFunc)
    local dialog = {content = str, ignoreCloseBtn = true, callback = okFunc}
    return g_commonModule:ShowDialog(dialog)
end

-- 强制关闭对话框
function DFCompatibleAPI:closeDialog()
    return g_commonModule:CloseDialog()
end

function DFCompatibleAPI:replaceView(cfg)
    return g_ModuleMgr:GetModule(ModuleName.VIEW_MODULE):ReplaceView(cfg)
end

-- TODO: ResourceManager为全局变量，需要去掉
function DFCompatibleAPI:loadImgSprite(resPath)
    local texture = ResourceManager:LoadAssetSprite(resPath)
    return texture
end

-- 头像加载（大丰麻将调用）
function DFCompatibleAPI:loadDynPic(path)
    local key = "GameModule/GuanZhang/_AssetsBundleRes/image/" .. path .. ".png"
    DFCompatibleAPI.headImage = DFCompatibleAPI.headImage or {}
    if not DFCompatibleAPI.headImage[key] then
        DFCompatibleAPI.headImage[key] = self:loadImgSprite(key)
        return DFCompatibleAPI.headImage[key]
    else
        return DFCompatibleAPI.headImage[key]
    end
end

-- 头像加载（大丰麻将调用）
function DFCompatibleAPI:loadCommonDynPic(path)
    local key = "Component/CommonComponent/Bundle/image/" .. path .. ".png"
    DFCompatibleAPI.headImage = DFCompatibleAPI.headImage or {}
    if not DFCompatibleAPI.headImage[key] then
        DFCompatibleAPI.headImage[key] = self:loadImgSprite(key)
        return DFCompatibleAPI.headImage[key]
    else
        return DFCompatibleAPI.headImage[key]
    end
end

function DFCompatibleAPI:soundPlay(name)
    local soundModule = g_ModuleMgr:GetModule(ModuleName.SOUND_MODULE)
    local path = string.format("GameModule/GuanZhang/_AssetsBundleRes/sound/%s.ogg", name)
    soundModule:PlayEffect(path)
end

function DFCompatibleAPI:soundCommonPlay(name)
    local soundModule = g_ModuleMgr:GetModule(ModuleName.SOUND_MODULE)
    local path = string.format("Component/CommonComponent/Bundle/sound/%s.ogg", name)
    soundModule:PlayEffect(path)
end

function DFCompatibleAPI:soundGetToggle(...)
    return true
end
return DFCompatibleAPI
