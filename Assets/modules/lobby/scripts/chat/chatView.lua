--[[
    ChatView 聊天界面
]]
local ChatView = {}
local logger = require "lobby/lcore/logger"
local fairy = require "lobby/lcore/fairygui"
local CS = _ENV.CS

function ChatView.showChatView()
    if ChatView.viewNode then
        logger.debug("showChatView -----------")
    else
        logger.debug("showChatView viewNode is nil.")
        _ENV.thisMod:AddUIPackage("lobby/fui_chat/lobby_chat")
        local view = fairy.UIPackage.CreateObject("lobby_chat", "chat")

        ChatView.viewNode = view
        --TODO:这里需要初始化列表
        ChatView.msgList = {}
        ChatView:initView()
        ChatView:testLists()
    end
    fairy.GRoot.inst:ShowPopup(ChatView.viewNode)
    local screenWidth = CS.UnityEngine.Screen.width
    -- local screenHeight = CS.UnityEngine.Screen.height
    ChatView.viewNode.x = screenWidth - 500
    ChatView.viewNode.y = 0
end

function ChatView:initView()
    -- button
    self.phraseBtn = self.viewNode:GetChild("phraseBtn")
    self.expressionBtn = self.viewNode:GetChild("expressionBtn")
    self.historyBtn = self.viewNode:GetChild("historyBtn")
    self.phraseBtn.onClick:Set(
        function()
            self:changeList(0)
            self.phraseBtn.selected = true
        end
    )
    self.expressionBtn.onClick:Set(
        function()
            self:changeList(1)
            self.expressionBtn.selected = true
        end
    )
    self.historyBtn.onClick:Set(
        function()
            self:changeList(2)
            self.historyBtn.selected = true
        end
    )
    -- list
    self.phraseList = self.viewNode:GetChild("phraseList").asList
    self.expressionList = self.viewNode:GetChild("expressionList").asList
    self.historyList = self.viewNode:GetChild("historyList").asList
    self.historyList.itemRenderer = function(index, obj)
        self:renderListItem(index, obj)
    end
    self.historyList.itemProvider = function(index)
        return self:getListItemResource(index)
    end
    self.historyList:SetVirtual()

    local sendBtn = self.viewNode:GetChild("sendBtn")
    sendBtn.onClick:Set(
        function()
            -- ChatView.win:Hide()
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
    -- self:updateHistoryList()
end

-- 更新表情列表
function ChatView:updateExpressionList()
    for _ = 1, 16 do
        local obj = fairy.UIPackage.CreateObject("lobby_chat", "chat_expression_item")
        self.expressionList:AddChild(obj)
    end
end

-- 更新短语列表
function ChatView:updatePhraseList()
    local phraseMap = {
        [0] = "你这牌打得也太好了吧。。。",
        [1] = "快点啊，都等到我花都谢了。。。",
        [2] = "真怕猪一样的队友。。。",
        [3] = "一走一停真有型，一秒一卡好潇洒。。。",
        [4] = "我炸你个桃花朵朵开。。。",
        [5] = "姑娘，你真是条汉子。。。",
        [6] = "风吹鸡蛋壳，牌去人安乐。。。",
        [7] = "搏一搏，单车变摩托。。。",
        [8] = "我就剩一张牌了。。。",
        [9] = "炸得好。。。"
    }
    self.phraseList.onClickItem:Add(
        function(onClickItem)
            self:addMsg(onClickItem.data.name == "2", onClickItem.data:GetChild("n0").text)
        end
    )
    self.phraseList:RemoveChildrenToPool()
    for i = 0, #phraseMap do
        local obj = self.phraseList:AddItemFromPool()
        obj.name = i
        local t = obj:GetChild("n0")
        t.text = phraseMap[i]
    end
end

-- 更新历史列表
-- function ChatView:updateHistoryList()
-- for i = 1, 16 do
--     if i % 2 == 0 then
--         -- self.phraseList:AddItemFromPool()
--         -- self.phraseList.itemRenderer = RenderListItem
--         local obj = fairy.UIPackage.CreateObject("lobby_chat", "chat_history_me_item")
--         local t = obj:GetChild("text")
--         t.text = "我说是多少打打 ad大神 阿萨德ad撒 啊大声地啊 阿萨德 ：" .. i
--         self.historyList:AddChild(obj)
--     else
--         local obj = fairy.UIPackage.CreateObject("lobby_chat", "chat_history_other_item")
--         local t = obj:GetChild("text")
--         t.text = "ni说是ds  啊大声地啊 阿萨德 ：" .. i
--         local n = obj:GetChild("name")
--         n.text = "我是 " .. i
--         self.historyList:AddChild(obj)
--     end
-- end
-- end

function ChatView:addMsg(isMe, str)
    -- logger.debug("addMsg : ", isMe)
    local s = #self.msgList + 1
    self.msgList[s] = {fromMe = isMe, msg = str}
    self.historyList.numItems = s
    self.historyList.scrollPane:ScrollBottom()
end

function ChatView:getListItemResource(index)
    local msg = self.msgList[index + 1]
    -- logger.debug("msg : ", msg)
    if msg.fromMe then
        return "ui://lobby_chat/chat_history_me_item"
    else
        return "ui://lobby_chat/chat_history_other_item"
    end
end

function ChatView:renderListItem(index, obj)
    local msg = self.msgList[index + 1]
    local t = obj:GetChild("text")
    t.text = msg.msg
end
return ChatView
