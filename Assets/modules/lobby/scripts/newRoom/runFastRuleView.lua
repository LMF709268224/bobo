--luacheck:no self

local RunFastRuleView = {}

local logger = require "lobby/lcore/logger"
local rapidJson = require("rapidjson")
local CS = _ENV.CS

--记录键值
local RecordKey = "GZRule"
local runFast = 8
local rules = {
    ["roomType"] = runFast,
    ["playerNumAcquired"] = 3,
    ["payNum"] = 4,
    ["payType"] = 0,
    ["handNum"] = 4,
    --游戏模块
    ["modName"] = "game1"
}

local configTable = {
    ["playerNumAcquired"] = {
        [1] = 4,
        [2] = 3,
        [3] = 2
    },
    ["payNum"] = {
        [1] = 24,
        [2] = 36,
        [3] = 66
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
    }
    -- 剩下还有些没对应上的配置
}

function RunFastRuleView.bindView(newRoomView)
    RunFastRuleView.unityViewNode = newRoomView.unityViewNode:GetChild("gzRule")
    RunFastRuleView.newRoomView = newRoomView

    RunFastRuleView:initAllView()

    local createBtn = RunFastRuleView.unityViewNode:GetChild("createRoomButton")
    createBtn.onClick:Set(
        function()
            RunFastRuleView:createRoom()
        end
    )
end

function RunFastRuleView:saveRule()
    logger.debug("RunFastRuleView:saveRule()")
    local key = {}
    -- 局数
    key[1] = RunFastRuleView:getToggleIndex(RunFastRuleView.toggleRoundCount)
    -- 支付
    key[2] = RunFastRuleView:getToggleIndex(RunFastRuleView.togglePay)

    local json = rapidJson.encode(key)
    logger.debug("RunFastRuleView:saveRule() ,key = ", key)
    local pp = CS.UnityEngine.PlayerPrefs
    pp.SetString(RecordKey, json)
end

function RunFastRuleView:initAllView()
    local consume = self.unityViewNode:GetChild("consumeCom")
    self.consumeText = consume:GetChild("consumeText")

    --局数
    self.toggleRoundCount = {}
    self.toggleRoundCount[1] = self.unityViewNode:GetChild("round4Button")
    self.toggleRoundCount[2] = self.unityViewNode:GetChild("round8Button")
    self.toggleRoundCount[3] = self.unityViewNode:GetChild("round16Button")

    self.toggleRoundCount[1]:GetChild("title").text = "4局"
    self.toggleRoundCount[2]:GetChild("title").text = "8局"
    self.toggleRoundCount[3]:GetChild("title").text = "16局"

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

    self.togglePay[1]:GetChild("title").text = "房主支付"
    self.togglePay[2]:GetChild("title").text = "AA支付"

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

    local pp = _ENV.CS.UnityEngine.PlayerPrefs

    if pp.HasKey(RecordKey) then
        local jsonStr = pp.GetString(RecordKey)
        if jsonStr and #jsonStr > 0 then
            local key = rapidJson.decode(jsonStr)

            self.toggleRoundCount[key[1]].selected = true
            self.togglePay[key[2]].selected = true
        end
    end

    -- self:updateComsumer()
    -- self:updateCostDiamond()
end

--获取规则设置的值
function RunFastRuleView:getToggleIndex(toggles)
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
function RunFastRuleView:resetTextColor(toggles, descriptios)
    for i, v in ipairs(toggles) do
        v.lable.text = string.format("<color=#FFFFFFFF>%s</color>", descriptios[i])
    end
end

--获取房间规则
function RunFastRuleView:getRules()
    local playCountIndex = self:getToggleIndex(self.toggleRoundCount)
    rules["handNum"] = configTable["handNum"][playCountIndex]

    local payIndex = self:getToggleIndex(self.togglePay)
    rules["payType"] = configTable["payType"][payIndex]

    -- 暂时不知道什么配置
    -- rules["doubleScoreWhenSelfDrawn"] = self.toggleKX[1].isOn

    -- rules["payNum"] = self:getCost(rules["payType"], rules["playerNumAcquired"], rules["handNum"])
    -- 暂时不知道什么配置
    return rules
end

function RunFastRuleView:getCost(payType, playerNum, handNum)
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
function RunFastRuleView:updateComsumer(priceCfgs)
    if priceCfgs ~= nil then
        self.priceCfg = priceCfgs[tostring(rules.roomType)]
    end

    local payIndex = self:getToggleIndex(self.togglePay)
    local payType = configTable["payType"][payIndex]

    local playCountIndex = self:getToggleIndex(self.toggleRoundCount)
    local handNum = configTable["handNum"][playCountIndex]

    -- 0 是不配置或者无限用户个数
    local playerNumAcquired = 0

    local cost = self:getCost(payType, playerNumAcquired, handNum)

    if cost == nil then
        logger.error(
            "No price cfg found, payType:" .. payType .. ", playerNumAcquired:" .. playerNumAcquired .. ", handNum:"
        )
    end

    logger.debug("cost:" .. cost)
    self.consumeText.text = cost
end

function RunFastRuleView:ToggleDefault(status, default)
    if status ~= nil then
        return status
    else
        return default
    end
end

function RunFastRuleView:createRoom()
    logger.debug("RunFastRuleView:createRoom")
    self.newRoomView:createRoom(self:getRules())
end

return RunFastRuleView
