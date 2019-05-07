--luacheck:no self

local RunFastRuleView = {}

local logger = require "lobby/lcore/logger"

--记录键值
-- local RecordKey = "createRoomView"
local dfRoomType = 8
local rules = {
    ["roomType"] = dfRoomType,
    ["playerNumAcquired"] = 3,
    ["payNum"] = 4,
    ["payType"] = 0,
    ["handNum"] = 4,
    --游戏ID
    ["GameID"] = 10034,
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

function RunFastRuleView.bindView(viewObj, newRoomView)
    RunFastRuleView.unityViewNode = viewObj
    RunFastRuleView.newRoomView = newRoomView

    RunFastRuleView:initAllView()

    local createBtn = RunFastRuleView.unityViewNode:GetChild("createRoomButton")
    createBtn.onClick:Set(
        function()
            RunFastRuleView:createRoom()
        end
    )
end

function RunFastRuleView:initAllView()
    -- 支付
    self.togglePay = {}
    self.togglePay[1] = self.unityViewNode:GetChild("ownerPayButton")
    self.togglePay[2] = self.unityViewNode:GetChild("aapPayButton")
    self.togglePay[1].selected = true
    self.togglePay[1].onClick:Set(
        function()
            self.togglePay[2].selected = false
            self:UpdateComsumer()
        end
    )
    self.togglePay[2].onClick:Set(
        function()
            self.togglePay[1].selected = false
            self:UpdateComsumer()
        end
    )

    --局数
    self.toggleCount = {}
    self.toggleCount[1] = self.unityViewNode:GetChild("round4Button")
    self.toggleCount[2] = self.unityViewNode:GetChild("round8Button")
    self.toggleCount[3] = self.unityViewNode:GetChild("round16Button")
    self.toggleCount[1].selected = true
    self.toggleCount[1].onClick:Set(
        function()
            self.toggleCount[2].selected = false
            self.toggleCount[3].selected = false
            self:UpdateComsumer()
        end
    )
    self.toggleCount[2].onClick:Set(
        function()
            self.toggleCount[1].selected = false
            self.toggleCount[3].selected = false
            self:UpdateComsumer()
        end
    )
    self.toggleCount[3].onClick:Set(
        function()
            self.toggleCount[1].selected = false
            self.toggleCount[2].selected = false
            self:UpdateComsumer()
        end
    )

    self:UpdateComsumer()
    self:updateCostDiamond()
end

--获取规则设置的值
function RunFastRuleView:GetToggleIndex(toggles)
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
function RunFastRuleView:ResetTextColor(toggles, descriptios)
    for i, v in ipairs(toggles) do
        v.lable.text = string.format("<color=#FFFFFFFF>%s</color>", descriptios[i])
    end
end

--获取房间规则
function RunFastRuleView:GetRules()
    local playCountIndex = self:GetToggleIndex(self.toggleCount)
    rules["handNum"] = configTable["handNum"][playCountIndex]

    local payIndex = self:GetToggleIndex(self.togglePay)
    rules["payType"] = configTable["payType"][payIndex]

    -- 暂时不知道什么配置
    -- rules["doubleScoreWhenSelfDrawn"] = self.toggleKX[1].isOn

    -- rules["payNum"] = self:GetCost(rules["payType"], rules["playerNumAcquired"], rules["handNum"])
    -- 暂时不知道什么配置
    return rules
end

--更新消耗数量
function RunFastRuleView:UpdateComsumer()
    local payIndex = self:GetToggleIndex(self.togglePay)
    local handIndex = self:GetToggleIndex(self.toggleCount)
    logger.debug("更新消耗数量  : ", payIndex, " : ", handIndex)

end

function RunFastRuleView:ToggleDefault(status, default)
    if status ~= nil then
        return status
    else
        return default
    end
end

function RunFastRuleView:calcAADiamond()
    local toggle = self:GetToggleIndex(self.togglePay)

    local isAA = false

    if toggle == 2 then
        isAA = true
    --self:UpdateComsumer(true)
    end

    self:UpdateComsumer(isAA)
end

function RunFastRuleView:OnUpdatePriceCfgs()
    self:updateCostDiamond()
end

function RunFastRuleView:createRoom()
    logger.debug("createRoom")
    self.newRoomView:createRoom(self:GetRules())


end

function RunFastRuleView:updateCostDiamond()

end

return RunFastRuleView
