--[[
    ChatView 聊天界面
]]
local ChatView = {}
local logger = require "lobby/lcore/logger"
local fairy = require "lobby/lcore/fairygui"

function ChatView.showChatView()
    if ChatView.viewNode then
        logger.debug("showChatView -----------")
    else
        logger.debug("showChatView viewNode is nil.")
        _ENV.thisMod:AddUIPackage("lobby/fui_chat/lobby_chat")
        local view = fairy.UIPackage.CreateObject("lobby_chat", "chat")

        local win = fairy.Window()
        win.contentPane = view
        win.modal = true
        -- local screenWidth = CS.UnityEngine.Screen.width
        -- local screenHeight = CS.UnityEngine.Screen.height
        -- win:SetXY(screenWidth / 2, screenHeight / 2)

        ChatView.viewNode = view
        ChatView.win = win

        ChatView:initView()
        -- 由于win隐藏，而不是销毁，隐藏后和GRoot脱离了关系，因此需要
        -- 特殊销毁
        _ENV.thisMod:RegisterCleanup(
            function()
                win:Dispose()
            end
        )

        view.onClick:Add(
            function()
                win:Hide()
            end
        )
    end
    ChatView:testLists()

    ChatView.win:Show()
end

function ChatView:initView()
    -- button
    self.phraseBtn = self.viewNode:GetChild("phraseBtn")
    self.expressionBtn = self.viewNode:GetChild("expressionBtn")
    self.historyBtn = self.viewNode:GetChild("historyBtn")
    self.phraseBtn.onClick:Add(
        function()
            self:changeList(0)
            self.phraseBtn.selected = true
        end
    )
    self.expressionBtn.onClick:Add(
        function()
            self:changeList(1)
            self.expressionBtn.selected = true
        end
    )
    self.historyBtn.onClick:Add(
        function()
            self:changeList(2)
            self.historyBtn.selected = true
        end
    )
    -- list
    self.phraseList = self.viewNode:GetChild("phraseList")
    self.expressionList = self.viewNode:GetChild("expressionList")
    self.historyList = self.viewNode:GetChild("historyList")

    local sendBtn = self.viewNode:GetChild("sendBtn")
    sendBtn.onClick:Add(
        function()
        end
    )
end

function ChatView:changeList(type)
    self.phraseBtn.selected = false
    self.expressionBtn.selected = false
    self.historyBtn.selected = false

    self.phraseList.visible = false
    self.expressionList.visible = false
    self.historyList.visible = false

    if type == 0 then
        self.phraseList.visible = true
    elseif type == 1 then
        self.expressionList.visible = true
    elseif type == 2 then
        self.historyList.visible = true
    end
end

function ChatView:testLists()
end

-- function ChatView.coShowDialog(msg, callBackOK, callBackCancel)
--     local waitCoroutine = coroutine.running()

--     local yes
--     local no

--     local resume = function()
--         local r, err = coroutine.resume(waitCoroutine)
--         if not r then
--             logger.error(debug.traceback(waitCoroutine, err))
--         end
--     end

--     if callBackOK then
--         yes = function()
--             callBackOK()
--             resume()
--         end
--     end

--     if callBackCancel then
--         no = function()
--             callBackCancel()
--             resume()
--         end
--     end

--     ChatView.showDialog(msg, yes, no)

--     coroutine.yield()
-- end

return ChatView
