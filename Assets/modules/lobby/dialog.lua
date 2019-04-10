--[[
    PromptDialog 提示框
]]
local Dialog = {}
local logger = require "lobby/lcore/logger"
local fairy = require "lobby/lcore/fairygui"

function Dialog.showDialog(msg, callBackOK, callBackCancel)
    if Dialog.viewNode then
        logger.debug("showDialog -----------")
    else
        logger.debug("showDialog viewNode is nil.")
        _ENV.thisMod:AddUIPackage("lobby/fui_dialog/lobby_dialog")
        local view = fairy.UIPackage.CreateObject("lobby_dialog", "dialog")
        Dialog.viewNode = view
    end

    local win = fairy.Window()
    win.contentPane = Dialog.viewNode
    win.modal = true
    win:SetXY(1136 / 2 - 190, 640 / 2 - 130)

    local label = Dialog.viewNode:GetChild("text")
    label.text = msg

    local yesBtn = Dialog.viewNode:GetChild("ok_btn")
    if callBackOK then
        yesBtn.visible = true
        yesBtn.onClick:Add(
            function()
                win:Hide()
                callBackOK()
            end
        )
    else
        yesBtn.visible = false
    end

    local noBtn = Dialog.viewNode:GetChild("cancel_btn")
    if callBackCancel then
        noBtn.visible = true
        noBtn.onClick:Add(
            function()
                win:Hide()
                callBackCancel()
            end
        )
    else
        noBtn.visible = false
    end
    win:Show()
end

return Dialog
