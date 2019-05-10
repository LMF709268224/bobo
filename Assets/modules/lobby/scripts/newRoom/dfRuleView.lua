--luacheck:no self

local DFRuleView = {}

local logger = require "lobby/lcore/logger"
local rapidJson = require("rapidjson")
local CS = _ENV.CS

--记录键值
local RecordKey = "DFMJRule"
local dfRoomType = 1
local rules = {
    ["roomType"] = dfRoomType,
    ["playerNumAcquired"] = 4,
    ["payNum"] = 24,
    ["payType"] = 0,
    ["handNum"] = 4,
    ["doubleScoreWhenSelfDrawn"] = true,
    ["doubleScoreWhenContinuousBanker"] = true,
    ["doubleScoreWhenZuoYuanZi"] = true,
    ["fengDingType"] = 0,
    ["dunziPointType"] = 0,
    --游戏模块
    ["modName"] = "game2"
}
local configTable = {
    ["playerNumAcquired"] = {
        [1] = 2,
        [2] = 3,
        [3] = 4
    },
    ["payNum"] = {
        [1] = 24,
        [2] = 36,
        [3] = 66
    },
    ["dunziPointType"] = {
        [1] = 0,
        [2] = 1
        --[3] = 2,
        --[4] = 3
    },
    ["dunziPointTypeBig"] = {
        [1] = 2,
        [2] = 3
        --[3] = 5,
        --[4] = 30
    },
    ["payType"] = {
        [1] = 0,
        [2] = 1
    },
    ["handNum"] = {
        [1] = 4,
        [2] = 8,
        [3] = 16
        --[4] = 32
    },
    ["fengDingType"] = {
        [1] = 0,
        [2] = 1,
        [3] = 2,
        [4] = 3
    },
    ["neededDiamond"] = {
        [1] = 32,
        [2] = 48,
        [3] = 88
        --[4] = 3
    },
    ["neededDiamond4ThreePlayers"] = {
        [1] = 24,
        [2] = 36,
        [3] = 66
    },
    ["neededDiamond4TwoPlayers"] = {
        [1] = 16,
        [2] = 24,
        [3] = 44
    }

    -- 剩下还有些没对应上的配置
}

function DFRuleView.bindView(newRoomView)
    DFRuleView.unityViewNode = newRoomView.unityViewNode:GetChild("damjRule")
    DFRuleView.newRoomView = newRoomView
    DFRuleView.priceCfg = newRoomView.priceCfgs[tostring(rules.roomType)]

    DFRuleView:initAllView()

    _ENV.thisMod:RegisterCleanup(
        function()
        end
    )

    local createBtn = DFRuleView.unityViewNode:GetChild("createRoomButton")
    createBtn.onClick:Set(
        function()
            DFRuleView:createRoom()
        end
    )
end

function DFRuleView:saveRule()
    logger.debug("DFRuleView:saveRule()")
    local key = {}
    -- 局数
    key[1] = DFRuleView:getToggleIndex(DFRuleView.toggleRoundCount)
    -- 支付
    key[2] = DFRuleView:getToggleIndex(DFRuleView.togglePay)
    -- 人数
    key[3] = DFRuleView:getToggleIndex(DFRuleView.togglePlayerNum)
    -- 封顶
    key[4] = DFRuleView:getToggleIndex(DFRuleView.toggleFengDingType)
    -- 墩子
    key[5] = DFRuleView:getToggleIndex(DFRuleView.toggleDunziPointType)
    -- 自摸加分
    key[6] = DFRuleView.toggleZMJF.selected
    -- 连庄加分
    key[7] = DFRuleView.toggleLZJF.selected
    -- 进院子
    key[8] = DFRuleView.toggleJYZ.selected

    local json = rapidJson.encode(key)
    logger.debug("DFRuleView:saveRule() ,key = ", key)
    local pp = CS.UnityEngine.PlayerPrefs
    pp.SetString(RecordKey, json)
end

function DFRuleView:initAllView()
    local consume = self.unityViewNode:GetChild("consumeCom")
    self.consumeText = consume:GetChild("consumeText")

    local pp = _ENV.CS.UnityEngine.PlayerPrefs
    local jsonStr = pp.GetString(RecordKey, "")
    local key = rapidJson.decode(jsonStr)

    --局数
    self.toggleRoundCount = {}
    self.toggleRoundCount[1] = self.unityViewNode:GetChild("round4Button")
    self.toggleRoundCount[2] = self.unityViewNode:GetChild("round8Button")
    self.toggleRoundCount[3] = self.unityViewNode:GetChild("round16Button")
    self.toggleRoundCount[key[1]].selected = true
    self.toggleRoundCount[1].onClick:Set(
        function()
            self:updateComsumer()
        end
    )
    self.toggleRoundCount[2].onClick:Set(
        function()
            self:updateComsumer()
        end
    )
    self.toggleRoundCount[3].onClick:Set(
        function()
            self:updateComsumer()
        end
    )

    -- 支付
    self.togglePay = {}
    self.togglePay[1] = self.unityViewNode:GetChild("ownerPayButton")
    self.togglePay[2] = self.unityViewNode:GetChild("aapPayButton")
    self.togglePay[key[2]].selected = true
    self.togglePay[1].onClick:Set(
        function()
            self.togglePay[2].selected = false
            self:updateComsumer()
        end
    )
    self.togglePay[2].onClick:Set(
        function()
            self.togglePay[1].selected = false
            self:updateComsumer()
        end
    )

    -- 人数
    self.togglePlayerNum = {}
    self.togglePlayerNum[1] = self.unityViewNode:GetChild("2Player")
    self.togglePlayerNum[2] = self.unityViewNode:GetChild("3Player")
    self.togglePlayerNum[3] = self.unityViewNode:GetChild("4Player")
    self.togglePlayerNum[key[3]].selected = true
    self.togglePlayerNum[1].onClick:Set(
        function()
            self:updateComsumer()
        end
    )
    self.togglePlayerNum[2].onClick:Set(
        function()
            self:updateComsumer()
        end
    )
    self.togglePlayerNum[3].onClick:Set(
        function()
            self:updateComsumer()
        end
    )

    -- 封顶
    self.toggleFengDingType = {}
    self.toggleFengDingType[1] = self.unityViewNode:GetChild("fengding1")
    self.toggleFengDingType[2] = self.unityViewNode:GetChild("fengding2")
    self.toggleFengDingType[3] = self.unityViewNode:GetChild("fengding3")
    self.toggleFengDingType[4] = self.unityViewNode:GetChild("fengding4")
    self.toggleFengDingType[key[4]].selected = true

    -- 墩子
    self.toggleDunziPointType = {}
    self.toggleDunziPointType[1] = self.unityViewNode:GetChild("dunzi1")
    self.toggleDunziPointType[2] = self.unityViewNode:GetChild("dunzi2")
    self.toggleDunziPointType[key[5]].selected = true

    self.toggleZMJF = self.unityViewNode:GetChild("zimojiafen")

    self.toggleZMJF.selected = key[6]

    self.toggleLZJF = self.unityViewNode:GetChild("lianzhuangjiafen")
    self.toggleLZJF.selected = key[7]

    self.toggleJYZ = self.unityViewNode:GetChild("jinyuanzi")
    self.toggleJYZ.selected = key[8]

    self:updateComsumer()
    -- self:updateCostDiamond()
end

--获取规则设置的值
function DFRuleView:getToggleIndex(toggles)
    for i, v in ipairs(toggles) do
        --log("test " .. v.gameObject.name ..","..tostring(v.isOn))
        -- if v.isOn then
        if v.selected then
            return i
        end
    end

    return 1
end

--重置Text的颜色
function DFRuleView:resetTextColor(toggles, descriptios)
    for i, v in ipairs(toggles) do
        v.lable.text = string.format("<color=#FFFFFFFF>%s</color>", descriptios[i])
    end
end

--获取房间规则
function DFRuleView:getRules()
    local roundIndex = self:getToggleIndex(self.toggleRoundCount)
    rules["handNum"] = configTable["handNum"][roundIndex]

    local payIndex = self:getToggleIndex(self.togglePay)
    rules["payType"] = configTable["payType"][payIndex]

    local playerNumIndex = self:getToggleIndex(self.togglePlayerNum)
    rules["playerNumAcquired"] = configTable["playerNumAcquired"][playerNumIndex]

    local fengdingIndex = self:getToggleIndex(self.toggleFengDingType)
    rules["fengDingType"] = configTable["fengDingType"][fengdingIndex]
    -- 暂时不知道什么配置
    -- rules["doubleScoreWhenSelfDrawn"] = self.toggleKX[1].isOn

    -- rules["payNum"] = self:getCost(rules["payType"], rules["playerNumAcquired"], rules["handNum"])
    -- 暂时不知道什么配置
    return rules
end

function DFRuleView:getCost(payType, playerNum, handNum)
    -- logError("payType:"..payType..", playerNum:"..playerNum..", handNum"..handNum)
    local key = "ownerPay" .. ":" .. tostring(playerNum) .. ":" .. handNum
    if payType == 1 then
        key = "aaPay" .. ":" .. tostring(playerNum) .. ":" .. handNum
    end

    local activityPriceCfg = self.priceCfg.activityPriceCfg
    if activityPriceCfg ~= nil and type(activityPriceCfg) == "table" and activityPriceCfg.discountCfg ~= nil then
        return activityPriceCfg.discountCfg[key]
    end

    if self.priceCfg.originalPriceCfg ~= nil and type(self.priceCfg.originalPriceCfg) == "table" then
        return self.priceCfg.originalPriceCfg[key]
    end

    return nil
end

--更新消耗数量
function DFRuleView:updateComsumer()
    local payIndex = self:getToggleIndex(self.togglePay)
    local payType = configTable["payType"][payIndex]

    local roundIndex = self:getToggleIndex(self.toggleRoundCount)
    local handNum = configTable["handNum"][roundIndex]

    local playerNumIndex = self:getToggleIndex(self.togglePlayerNum)
    local playerNumAcquired = configTable["playerNumAcquired"][playerNumIndex]

    local cost = self:getCost(payType, playerNumAcquired, handNum)

    if cost == nil then
        logger.error(
            "No price cfg found, payType:" .. payType .. ", playerNumAcquired:" .. playerNumAcquired .. ", handNum:"
        )
    end

    logger.debug("cost:" .. cost)
    self.consumeText.text = cost
end

function DFRuleView:ToggleDefault(status, default)
    if status ~= nil then
        return status
    else
        return default
    end
end

function DFRuleView:createRoom()
    logger.debug("DFRuleView:createRoom")
    self.newRoomView:createRoom(self:getRules())
end

return DFRuleView
