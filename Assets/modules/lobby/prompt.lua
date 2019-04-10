--[[
    Prompt 提示框
]]
local Prompt = {}
local logger = require "lobby/lcore/logger"
local fairy = require "lobby/lcore/fairygui"

function Prompt.showPrompt(msg)
    if Prompt.viewNode then
        logger.debug("showPrompt -----------")
    else
        logger.debug("showPrompt viewNode is nil.")
        _ENV.thisMod:AddUIPackage("lobby/fui_dialog/lobby_dialog")
        local view = fairy.UIPackage.CreateObject("lobby_dialog", "prompt")
        Prompt.viewNode = view
    end

    local label = Prompt.viewNode:GetChild("text")
    label.text = msg

    fairy.GRoot.inst:ShowPopup(Prompt.viewNode)
end

return Prompt
