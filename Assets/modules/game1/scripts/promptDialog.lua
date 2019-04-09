--[[
    PromptDialog 提示框
]]
local PromptDialog = {}
local logger = require "lobby/lcore/logger"
local fairy = require "lobby/lcore/fairygui"

function PromptDialog.showDialog(msg)
    if PromptDialog.viewNode then
        logger.debug("showDialog -----------")
    else
        logger.debug("showDialog viewNode is nil.")
        _ENV.thisMod:AddUIPackage("lobby/fui_dialog/lobby_dialog")
        local view = fairy.UIPackage.CreateObject("lobby_dialog", "dialog")
        PromptDialog.viewNode = view
    end

    local label = PromptDialog.viewNode:GetChild("text")
    label.text = msg

    fairy.GRoot.inst:ShowPopup(PromptDialog.viewNode)
end

return PromptDialog
