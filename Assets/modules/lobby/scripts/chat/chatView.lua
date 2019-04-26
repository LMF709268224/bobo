--[[
    ChatView 聊天界面
]]
local ChatView = {}
local logger = require "lobby/lcore/logger"
local fairy = require "lobby/lcore/fairygui"
local httpHelper = require "lobby/lcore/httpHelper"
local urlpathsCfg = require "lobby/lcore/urlpathsCfg"
local proto = require "lobby/scripts/proto/proto"
local CS = _ENV.CS

function ChatView.showChatView()
    if ChatView.viewNode then
        logger.debug("showChatView -----------")
    else
        logger.debug("showChatView viewNode is nil.")
        _ENV.thisMod:AddUIPackage("lobby/fui_chat/lobby_chat")
        local view = _ENV.thisMod:CreateUIObject("lobby_chat", "chat")

        ChatView.viewNode = view
        ChatView:initView()
        ChatView:testLists()

        _ENV.thisMod:RegisterCleanup(
            function()
                view:Dispose()
            end
        )
        _ENV.thisMod:SetMsgListener(
            "lobby_chat",
            function(str)
                logger.debug("SetMsgListener : ", str)
                -- ChatView:addMsg()
            end
        )
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
    self.phraseList.itemRenderer = function(index, obj)
        self:renderPhraseListItem(index, obj)
    end
    self.phraseList:SetVirtual()

    self.expressionList = self.viewNode:GetChild("expressionList").asList

    self.historyList = self.viewNode:GetChild("historyList").asList
    self.historyList.itemRenderer = function(index, obj)
        self:renderHistoryListItem(index, obj)
    end
    self.historyList.itemProvider = function(index)
        return self:getHistoryListItemResource(index)
    end
    self.historyList:SetVirtual()

    local chatText = self.viewNode:GetChild("chatText")
    local sendBtn = self.viewNode:GetChild("sendBtn")
    sendBtn.onClick:Set(
        function()
            self:sendMsg(chatText.text)
            chatText.text = ""
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
    self:updatePhraseList()
    self:updateExpressionList()
    self:updateHistoryList()
end

-- 更新表情列表
function ChatView:updateExpressionList()
    for _ = 1, 16 do
        local obj = _ENV.thisMod:CreateUIObject("lobby_chat", "chat_expression_item")
        self.expressionList:AddChild(obj)
    end
end

-- 更新短语列表
function ChatView:updatePhraseList()
    self.phraseMap = {
        [1] = "快点啊，都等到我花都谢了。。。",
        [2] = "真怕猪一样的队友。。。",
        [3] = "一走一停真有型，一秒一卡好潇洒。。。",
        [4] = "我炸你个桃花朵朵开。。。",
        [5] = "姑娘，你真是条汉子。。。",
        [6] = "风吹鸡蛋壳，牌去人安乐。。。",
        [7] = "搏一搏，单车变摩托。。。",
        [8] = "我就剩一张牌了。。。",
        [9] = "炸得好。。。",
        [10] = "你这牌打得也太好了吧。。。",
        [11] = "屌爆了啊",
        [12] = "我就剩两张牌了。。。"
    }
    self.phraseList.onClickItem:Add(
        function(onClickItem)
            self:sendMsg(onClickItem.data:GetChild("n0").text)
        end
    )

    self.phraseList.numItems = #self.phraseMap
end

-- 更新历史列表
function ChatView:updateHistoryList()
    --TODO:这里需要初始化列表
    self.msgList = {}
end

function ChatView:sendMsg(str)
    -- TODO: 请求大厅 发送消息
    -- local co = coroutine.running()
    -- 请求服务器获取模块更新信息
    local tk = CS.UnityEngine.PlayerPrefs.GetString("token", "")
    local url = urlpathsCfg.rootURL .. urlpathsCfg.chat .. "?tk=" .. tk
    local rapidjson = require("rapidjson")
    local jsonString = rapidjson.encode({msg = str})
    local chat = {
        scope = proto.lobby.ChatScopeType.InRoom,
        dataType = proto.lobby.ChatDataType.Text,
        data = jsonString
    }
    local body = proto.encodeMessage("lobby.MsgChat", chat)
    httpHelper.post(
        self.viewNode,
        url,
        body,
        function(req, resp)
            if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
                logger.debug("send msg ok")
                logger.debug("---------------------: ", resp.Data)
            else
                logger.debug("send msg error : ", req.State)
            end
        end
    )
    -- coroutine.yield()
    self:addMsg(true, str)
end

function ChatView:addMsg(isMe, str)
    local s = #self.msgList + 1
    self.msgList[s] = {fromMe = isMe, msg = str}
    self.historyList.numItems = s
    self.historyList.scrollPane:ScrollBottom()
end

function ChatView:getHistoryListItemResource(index)
    local msg = self.msgList[index + 1]
    if msg.fromMe then
        return "ui://lobby_chat/chat_history_me_item"
    else
        return "ui://lobby_chat/chat_history_other_item"
    end
end

function ChatView:renderHistoryListItem(index, obj)
    local msg = self.msgList[index + 1]
    local t = obj:GetChild("text")
    t.text = msg.msg
end

function ChatView:renderPhraseListItem(index, obj)
    local msg = self.phraseMap[index + 1]
    local t = obj:GetChild("n0")
    t.text = msg
end

return ChatView
