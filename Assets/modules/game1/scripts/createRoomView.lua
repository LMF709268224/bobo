--luacheck:no self

local CreateRoomView = {}

local fairy = require "lobby/lcore/fairygui"
local logger = require "lobby/lcore/logger"
local urlpathsCfg = require "lobby/lcore/urlpathsCfg"
local httpHelper = require "lobby/lcore/httpHelper"
local proto = require "lobby/scripts/proto/proto"
local rapidjson = require("rapidjson")
local CS = _ENV.CS

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
    ["GameID"] = 10034
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

function CreateRoomView.new()
    if CreateRoomView.unityViewNode then
        logger.debug("CreateRoomView ---------------------")
    else
        _ENV.thisMod:AddUIPackage("fgui/runfast")
        local viewObj = _ENV.thisMod:CreateUIObject("runfast", "room_create")
        CreateRoomView.unityViewNode = viewObj

        local win = fairy.Window()
        win.contentPane = CreateRoomView.unityViewNode
        CreateRoomView.win = win

        --初始化View
        CreateRoomView:initAllView()

        -- 由于win隐藏，而不是销毁，隐藏后和GRoot脱离了关系，因此需要
        -- 特殊销毁
        _ENV.thisMod:RegisterCleanup(
            function()
                win:Dispose()
            end
        )
    end

    local createBtn = CreateRoomView.unityViewNode:GetChild("createBtn")
    createBtn.onClick:Set(
        function()
            CreateRoomView:createRoom()
        end
    )

    CreateRoomView.win:Show()
end

function CreateRoomView:initAllView()
    -- 支付
    self.togglePay = {}
    self.togglePay[1] = self.unityViewNode:GetChild("pay1")
    self.togglePay[2] = self.unityViewNode:GetChild("pay2")
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
    -- self.togglePay[1].onChanged.Add(
    --     function()
    --         self:UpdateComsumer(false)
    --     end
    -- )
    -- self.togglePay[2].onChanged.Add(
    --     function()
    --         self:UpdateComsumer(false)
    --     end
    -- )

    --局数
    self.toggleCount = {}
    self.toggleCount[1] = self.unityViewNode:GetChild("hand4")
    self.toggleCount[2] = self.unityViewNode:GetChild("hand8")
    self.toggleCount[3] = self.unityViewNode:GetChild("hand16")
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
    --获取记录刷新界面
    -- if UnityEngine.PlayerPrefs.HasKey(RecordKey) then
    --     local json = UnityEngine.PlayerPrefs.GetString(RecordKey)
    --     --log("test  json = " .. json)
    --     if json and #json > 0 then
    --         local key = Json.decode(json)

    --         local toggle = self.toggleCount[key[1]] or self.toggleCount[1]
    --         toggle.isOn = true

    --         toggle = self.togglePlayerNum[key[2]] or self.togglePlayerNum[1]
    --         toggle.isOn = true

    --         toggle = self.togglePay[key[3]] or self.togglePay[2]
    --         toggle.isOn = true

    --         toggle = self.toggleFengDing[key[4]] or self.toggleFengDing[2]
    --         toggle.isOn = true

    --         toggle = self.toggleDunZi[key[5]] or self.toggleDunZi[1]
    --         toggle.isOn = true

    --         self.toggleKX[1].isOn = self:ToggleDefault(key[6], true)
    --         self.toggleKX[2].isOn = self:ToggleDefault(key[7], true)
    --         self.toggleKX[3].isOn = self:ToggleDefault(key[8], false)

    --         --key[3] == 2 表示是AA支付
    --         self:UpdateComsumer(key[3] == 2)
    --     end
    -- end

    --退出时记录
    -- self.OnDestroy = function()
    --     local key = {}
    --     key[1] = self:GetToggleIndex(self.toggleCount)
    --     key[2] = self:GetToggleIndex(self.togglePlayerNum)
    --     key[3] = self:GetToggleIndex(self.togglePay)
    --     key[4] = self:GetToggleIndex(self.toggleFengDing)
    --     key[5] = self:GetToggleIndex(self.toggleDunZi)
    --     key[6] = self.toggleKX[1].isOn
    --     key[7] = self.toggleKX[2].isOn
    --     key[8] = self.toggleKX[3].isOn
    --     local json = Json.encode(key)
    --     UnityEngine.PlayerPrefs.SetString(RecordKey, json)

    --     dispatcher:unregister("LOAD_PRICES_CFG", self, self.OnUpdatePriceCfgs)
    -- end

    self:UpdateComsumer()
    self:updateCostDiamond()
end

--获取规则设置的值
function CreateRoomView:GetToggleIndex(toggles)
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
function CreateRoomView:ResetTextColor(toggles, descriptios)
    for i, v in ipairs(toggles) do
        v.lable.text = string.format("<color=#FFFFFFFF>%s</color>", descriptios[i])
    end
end

-- function CreateRoomView:GetCost(payType, playerNum, handNum)
--     -- logError("payType:"..payType..", playerNum:"..playerNum..", handNum"..handNum)
--     local key = "ownerPay" .. ":" .. tostring(playerNum) .. ":" .. handNum
--     if payType == 1 then
--         key = "aaPay" .. ":" .. tostring(playerNum) .. ":" .. handNum
--     end

--     local originalPrice = yuePaiLogic:GetOriginalPrice(dfRoomType, key)
--     return originalPrice

--     -- return payConfig[key]
-- end

--获取房间规则
function CreateRoomView:GetRules()
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
function CreateRoomView:UpdateComsumer()
    local payIndex = self:GetToggleIndex(self.togglePay)
    local handIndex = self:GetToggleIndex(self.toggleCount)
    logger.debug("更新消耗数量  : ", payIndex, " : ", handIndex)

    -- local playerNum = configTable["playerNumAcquired"][playerNumIndex]
    -- --logError("playerNum == "..playerNum)
    -- if playerNum == 4 then
    --     self.comsumer = configTable.neededDiamond
    -- elseif playerNum == 3 then
    --     self.comsumer = configTable.neededDiamond4ThreePlayers
    -- elseif playerNum == 2 then
    --     self.comsumer = configTable.neededDiamond4TwoPlayers
    -- end
    -- if isAA then
    --     for i = 1, 3 do
    --         --logError("comsumer == "..self.comsumer[i])
    --         --math.ceil 向上取整
    --         self.costLabels[i].text = isAA and ("每人" .. math.ceil(self.comsumer[i] / playerNum)) or self.comsumer[i]
    --     end
    -- else
    --     for i = 1, 3 do
    --         self.costLabels[i].text = self.comsumer[i]
    --     end
    -- end
    -- for i = 1, 3 do
    --     self.costLabels[i].text = isAA and ("每人" ..  math.ceil(self.comsumer[i] / playerNum)) or self.comsumer[i]
    -- end
end

function CreateRoomView:ToggleDefault(status, default)
    if status ~= nil then
        return status
    else
        return default
    end
end

function CreateRoomView:calcAADiamond()
    local toggle = self:GetToggleIndex(self.togglePay)

    local isAA = false

    if toggle == 2 then
        isAA = true
    --self:UpdateComsumer(true)
    end

    self:UpdateComsumer(isAA)
end

function CreateRoomView:OnUpdatePriceCfgs()
    self:updateCostDiamond()
end

function CreateRoomView:updateCostDiamond()
    -- local payIndex = self:GetToggleIndex(self.togglePay)
    -- local payType = configTable["payType"][payIndex]
    -- local playerNumIndex = self:GetToggleIndex(self.togglePlayerNum)
    -- local playerNumAcquired = configTable["playerNumAcquired"][playerNumIndex]
    -- local playCountIndex = self:GetToggleIndex(self.toggleCount)
    -- local handNum = configTable["handNum"][playCountIndex]
    -- local cost = self:GetCost(payType, playerNumAcquired, handNum)
    -- -- self.costDiamond.text = "x"..cost
    -- print("CreateRoomView:updateCostDiamond()----------------cost = " .. tostring(cost))
    -- if cost == nil then
    --     g_commonModule:ShowTip("获取不到支付配置")
    --     return
    -- end
    -- self.costDiamond.text = "x" .. cost
    -- self.discount:SetActive(false)
    -- local discountPrice = yuePaiLogic:GetDiscountPrice(dfRoomType, payType, playerNumAcquired, handNum)
    -- if discountPrice ~= nil then
    --     self.discountPrice.text = "x" .. discountPrice .. "）"
    --     self.discount:SetActive(true)
    -- end
    -- print("CreateRoomView:updateCostDiamond()----------------discountPrice = " .. tostring(discountPrice))
end

function CreateRoomView:enterGame()
    --testGame1UI()
    local mylobbyView = fairy.GRoot.inst:GetChildAt(0)
    fairy.GRoot.inst:RemoveChild(mylobbyView)
    fairy.GRoot.inst:CleanupChildren()

    local parameters = {
        gameType = "1",
        serverUUID = "",
        myUser = "",
        roomInfo = ""
    }

    local jsonString = rapidjson.encode(parameters)
    _ENV.thisMod:LaunchGameModule("game1", jsonString)
end

function CreateRoomView:createRoom(roomInfo)
    logger.debug("------CreateRoomView----enter room roomInfo:", roomInfo)

    local tk = CS.UnityEngine.PlayerPrefs.GetString("token", "")
    local url = urlpathsCfg.rootURL .. urlpathsCfg.createRoom .. "?tk=" .. tk
    local jsonString = rapidjson.encode(self:GetRules())
    local createRoomReq = {
        config = jsonString
    }
    local body = proto.encodeMessage("lobby.MsgCreateRoomReq", createRoomReq)
    httpHelper.post(
        self.unityViewNode,
        url,
        body,
        function(req, resp)
            if req.State == CS.BestHTTP.HTTPRequestStates.Finished then
                logger.debug("create room ok--------: ", resp.Data)
            else
                logger.debug("create room error : ", req.State)
            end
        end
    )
    -- local token = g_dataModule:GetUserData():GetToken()
    -- local params = "tk=" .. token .. "&roomID=" .. roomInfo.roomID
    -- local url = roomInfo.gameServerURL .. "?" .. params
    -- local uid = g_dataModule:GetUserData():GetUID()
    -- local myUser = {userID = tostring(uid)}

    -- local daFengModule = nil

    -- xpcall(
    --     function()
    --         daFengModule = require("DaFengMaJiang/Script/dfMahjong/DaFengModule")
    --     end,
    --     function(msg)
    --         daFengModule = nil
    --         logError("----------CreateRoomView:EnterGame: 进入游戏失败原因：" .. msg)
    --         local error = string.format("游戏不存在!")
    --         g_commonModule:ShowTip(error)
    --     end
    -- )

    -- if daFengModule then
    --     local dispatcher = g_ModuleMgr:GetModule(ModuleName.DISPATCH_MODULE)
    --     g_ModuleMgr:AddModule(daFengModule.moduleName, daFengModule)
    --     dispatcher:dispatch("START_DAFENG", url, myUser, roomInfo)
    -- end
end

return CreateRoomView
