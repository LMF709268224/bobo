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
    -- local position = Prompt.viewNode.position
    local label = Prompt.viewNode:GetChild("text")
    label.text = msg

    fairy.GRoot.inst:ShowPopup(Prompt.viewNode)
    Prompt.viewNode:SetXY(1136 / 2, 640 / 2)

    local gtweener = fairy.Gtween.DelayedCall(2.0)
    gtweener:OnComplete(
        function()
            fairy.GRoot.inst:HidePopup()
        end
    )
end

return Prompt
