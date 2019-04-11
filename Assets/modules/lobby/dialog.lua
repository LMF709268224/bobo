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

		local win = fairy.Window()
		win.contentPane = view
		win.modal = true
		local screenWidth = CS.UnityEngine.Screen.width
		local screenHeight = CS.UnityEngine.Screen.height
		win:SetXY(screenWidth / 2, screenHeight / 2)

		Dialog.viewNode = view
		Dialog.win = win

		-- 由于win隐藏，而不是销毁，隐藏后和GRoot脱离了关系，因此需要
		-- 特殊销毁
		_ENV.thisMod:RegisterCleanup(function()
			win:Dispose()
		end)
    end

    local label = Dialog.viewNode:GetChild("text")
    label.text = msg

    local yesBtn = Dialog.viewNode:GetChild("ok_btn")
    if callBackOK then
		logger.debug('showDialog, callBackOK valid')
        yesBtn.visible = true
        yesBtn.onClick:Add(
            function()
                Dialog.win:Hide()
                callBackOK()
            end
        )
    else
        yesBtn.visible = false
    end

    local noBtn = Dialog.viewNode:GetChild("cancel_btn")
    if callBackCancel then
		logger.debug('showDialog, callBackCancel valid')
        noBtn.visible = true
        noBtn.onClick:Add(
            function()
                Dialog.win:Hide()
                callBackCancel()
            end
        )
    else
        noBtn.visible = false
    end
    Dialog.win:Show()
end

function Dialog.coShowDialog(msg, callBackOK, callBackCancel)
    local waitCoroutine = coroutine.running()

	local yes
	local no

	local resume = function()
        local r, err = coroutine.resume(waitCoroutine)
        if not r then
            logger.error(debug.traceback(waitCoroutine, err))
        end
	end

	if callBackOK then
		yes = function()
			callBackOK()
			resume()
		end
	end

	if callBackCancel then
		no = function()
			callBackCancel()
			resume()
		end
	end

	 Dialog.showDialog(msg, yes, no)

	 coroutine.yield()
end

return Dialog
