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
        ChatView:testLists()
        -- 由于win隐藏，而不是销毁，隐藏后和GRoot脱离了关系，因此需要
        -- 特殊销毁
        _ENV.thisMod:RegisterCleanup(
            function()
                win:Dispose()
            end
        )

        view.onClick:Add(
            function()
                -- win:Hide()
            end
        )
    end

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
    self.phraseList = self.viewNode:GetChild("phraseList").asList
    self.expressionList = self.viewNode:GetChild("expressionList").asList
    self.historyList = self.viewNode:GetChild("historyList").asList
    -- item
    -- self.expressionItem = fairy.UIPackage.CreateObject("lobby_chat", "chat_expression_item")
    -- self.historyMeItem = fairy.UIPackage.CreateObject("lobby_chat", "chat_history_me_item")
    -- self.historyOtherItem = fairy.UIPackage.CreateObject("lobby_chat", "chat_history_other_item")
    -- self.phraseItem = fairy.UIPackage.CreateObject("lobby_chat", "chat_phrase_item")

    local sendBtn = self.viewNode:GetChild("sendBtn")
    sendBtn.onClick:Add(
        function()
            ChatView.win:Hide()
        end
    )
    local closeBtn = self.viewNode:GetChild("close")
    closeBtn.onClick:Add(
        function()
            ChatView.win:Hide()
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
    -- self.expressionItem = fairy.UIPackage.CreateObject("lobby_chat", "chat_expression_item")
    -- self.historyMeItem = fairy.UIPackage.CreateObject("lobby_chat", "chat_history_me_item")
    -- self.historyOtherItem = fairy.UIPackage.CreateObject("lobby_chat", "chat_history_other_item")
    -- self.phraseItem = fairy.UIPackage.CreateObject("lobby_chat", "chat_phrase_item")
    self:updatePhraseList()
    self:updateExpressionList()
    self:updateHistoryList()
end

-- 更新表情列表
function ChatView:updateExpressionList()
    for i = 1, 16 do
        local obj = fairy.UIPackage.CreateObject("lobby_chat", "chat_expression_item")
        self.expressionList:AddChild(obj)
    end
end

-- 更新短语列表
function ChatView:updatePhraseList()
    -- local RenderListItem = function(index, obj)
    --     local t = obj:GetChild("n0")
    --     t.text = "呵呵呵呵 ：" .. index
    -- end
    -- self.phraseList.itemRenderer = RenderListItem
    -- self.phraseList.numItems = 12
    self.phraseList.onClickItem:Add(
        function(onClickItem)
            logger.debug("点击短语item : ", onClickItem.data.name)
            logger.debug("点击短语item : ", onClickItem.data:GetChild("n0").text)
        end
    )
    self.phraseList:RemoveChildrenToPool()
    for i = 1, 16 do
        local obj = self.phraseList:AddItemFromPool()
        obj.name = "o:" .. i
        -- local obj = fairy.UIPackage.CreateObject("lobby_chat", "chat_phrase_item")
        local t = obj:GetChild("n0")
        t.text = "哈哈哈哈哈 ：" .. i
        -- self.phraseList:AddChild(obj)
    end
end

-- 更新历史列表
function ChatView:updateHistoryList()
    for i = 1, 16 do
        if i % 2 == 0 then
            -- self.phraseList:AddItemFromPool()
            -- self.phraseList.itemRenderer = RenderListItem
            local obj = fairy.UIPackage.CreateObject("lobby_chat", "chat_history_me_item")
            local t = obj:GetChild("text")
            t.text = "我说是多少打打 ad大神 阿萨德ad撒 啊大声地啊 阿萨德 ：" .. i
            self.historyList:AddChild(obj)
        else
            local obj = fairy.UIPackage.CreateObject("lobby_chat", "chat_history_other_item")
            local t = obj:GetChild("text")
            t.text = "ni说是ds  啊大声地啊 阿萨德 ：" .. i
            local n = obj:GetChild("name")
            n.text = "我是 " .. i
            self.historyList:AddChild(obj)
        end
    end
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
