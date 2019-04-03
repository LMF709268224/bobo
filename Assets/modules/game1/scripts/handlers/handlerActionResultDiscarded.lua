--[[
    处理有玩家打出一张牌结果通知
]]
local Handler = {}
Handler.VERSION = "1.0"

function Handler.onMsg(actionResultMsg, room)
    --logger.debug(' Discarded result')
    --TODO:开启倒计时
    --room:startDiscardCountdown(15)

    local targetChairID = actionResultMsg.targetChairID
    local player = room:getPlayerByChairID(targetChairID)
    local discardTileIds = actionResultMsg.actionHand.cards
    -- actionResultMsg.actionHand.cardHandType    -- 牌组类型  用于显示文字提示（比如：顺子  对子）

    for _, v in ipairs(discardTileIds) do
        --从手牌移除
        player:removeTileFromHand(v)
        --加到打出牌列表
        player:addDicardedTile(v)
    end

    --排一下序,sortHands会根据tilesHand表格是否为nil，做出排序选择
    player:sortHands()

    --更新UI
    player:hand2UI()
    player:discarded2UI(discardTileIds)
    -- player:showCardHandType(actionResultMsg.actionHand.cardHandType, discardTileIds[1])

    --出牌音效
    -- dfCompatibleAPI:soundPlay("effect/effect_chupai")
    --logError("chatIsOn : "..tostring(Sound.GetToggle("chatIsOn")))
    --如果打出去的牌是在本人的听牌列表中，要做一个减法
    -- local me = room:me()
    -- if player == me then
    --     return
    -- end

    -- local readyHandList = me.readyHandList
    -- if readyHandList ~= nil and #readyHandList > 0 then
    --     for i = 1, #me.readyHandList, 2 do
    --         if readyHandList[i] == discardTileId then
    --             if readyHandList[i+1] > 1 then
    --                 readyHandList[i+1] = readyHandList[i+1]-1
    --             else
    --                 table.remove(readyHandList,i+1)
    --                 table.remove(readyHandList,i)
    --             end
    --             me.readyHandList = readyHandList
    --             break
    --         end
    --     end
    -- end
end

return Handler
