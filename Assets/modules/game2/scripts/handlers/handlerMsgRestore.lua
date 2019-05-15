--[[
    处理断线恢复，奔溃后恢复
]]
local Handler = {}

local proto = require "scripts/proto/proto"
-- local logger = require "lobby/lcore/logger"

function Handler.onMsg(msgData, room)
    --print('llwant, handle room restore')

    --掉线恢复时，是通过MsgRestore下发的
    local msgRestore = proto.decodeMessage("mahjong.MsgRestore", msgData)
    -- msgRestore:ParseFromString(msgData)

    --首先清空所有玩家的牌列表
    for _, p in pairs(room.players) do
        p:resetForNewHand()
    end

    --一手牌数据
    local msgDeal = msgRestore.msgDeal
    room.bankerChairID = msgDeal.bankerChairID
    room.isContinuousBanker = msgDeal.isContinuousBanker
    room.windFlowerID = msgDeal.windFlowerID
    room.tilesInWall = msgDeal.tilesInWall
    --大丰 1：就表示家家庄    -- 盐城 >0 表示加价局计数
    room.markup = msgDeal.markup
    -- print("llwant,handlerMsgRestore ---------------" .. tostring(msgDeal.markup))
    --print("llwant,msgDeal.markup : " .. msgDeal.markup)
    -- print("llwant , handlerMsgRestore.room.markup : " .. tostring(room.markup))
    --起手听状态
    for _, chairID in ipairs(msgRestore.readyHandChairs) do
        local player = room:getPlayerByChairID(chairID)
        player:richiIconShow(true)
    end

    room:updateTilesInWallUI()
    --TODO:根据风圈修改
    room.roomView:setRoundMask(1)
    --TODO:修改家家庄标志
    -- room.roomView:setJiaJiaZhuang()
    --TODO:修改庄家标志
    room:setBankerFlag()
    --清理吃牌界面
    room:cleanUI()
    --保存每一个玩家的牌列表
    local playerTileLists = msgDeal.playerTileLists
    for _, v in ipairs(playerTileLists) do
        local playerTileList = v
        local chairID = v.chairID
        local player = room:getPlayerByChairID(chairID)

        --填充手牌列表，仅自己有手牌列表，对手只有手牌张数
        if player:isMe() then
            player:addHandTiles(playerTileList.tilesHand)
        else
            player.tileCountInHand = playerTileList.tileCountInHand
        end

        --填充花牌列表
        player:addFlowerTiles(playerTileList.tilesFlower)

        --填充打出去的牌列表
        player:addDiscardedTiles(playerTileList.tilesDiscard)

        --填充面子牌列表
        player:addMelds(playerTileList.melds)

        if player.chairID == room.bankerChairID then
            room.roomView:setWaitingPlayer(player)
        end
    end

    --自己手牌排一下序
    local mySelf = room:me()
    local newDraw = msgRestore.isMeNewDraw
    mySelf:sortHands(newDraw)

    --显示各个玩家的手牌（对手只显示暗牌）和花牌和打出去的牌
    for _, p in pairs(room.players) do
        p:hand2UI(not newDraw)

        p:flower2UI()
        local newDiscarded = false
        if p.chairID == msgRestore.lastDiscaredChairID then
            room.roomView:setWaitingPlayer(p)
            newDiscarded = true
        end

        p:discarded2UI(newDiscarded, msgRestore.waitDiscardReAction)
    end
end

return Handler
