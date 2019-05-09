--[[
    处理有玩家打出一张牌结果通知
]]
local Handler = {}
Handler.VERSION = "1.0"

function Handler.onMsg(actionResultMsg, room)
    print("llwant, Discarded result")

    local targetChairID = actionResultMsg.targetChairID
    local player = room:getPlayerByChairID(targetChairID)
    local discardTileId = actionResultMsg.actionTile

    local me = room:me()
    if player ~= me or room:isReplayMode() then
        player:discardOutTileID(discardTileId)
    end

    --清理吃牌界面
    room:cleanUI()
    --加到打出牌列表
    player:addDicardedTile(discardTileId)
    player:discarded2UI(true, actionResultMsg.waitDiscardReAction)

    --logError("chatIsOn : "..tostring(Sound.GetToggle("chatIsOn")))
    --如果打出去的牌是在本人的听牌列表中，要做一个减法
    if player == me then
        return
    end

    local readyHandList = me.readyHandList
    if readyHandList ~= nil and #readyHandList > 0 then
        for i = 1, #me.readyHandList, 2 do
            if readyHandList[i] == discardTileId then
                if readyHandList[i + 1] > 1 then
                    readyHandList[i + 1] = readyHandList[i + 1] - 1
                else
                    table.remove(readyHandList, i + 1)
                    table.remove(readyHandList, i)
                end
                me.readyHandList = readyHandList
                break
            end
        end
    end
end

return Handler
