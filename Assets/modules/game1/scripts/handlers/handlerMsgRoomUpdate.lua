--[[
    房间更新
    服务器通过该消息，通知客户端包括如下事件：
        有玩家进入房间
        有玩家离开房间
        有玩家状态改变，例如变为离线，准备好，等等
]]
local Handler = {}

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

function Handler.onMsg(msgData, room)
    logger.debug(" handle room update")

    local msgRoomUpdate = proto.decodeMessage("pokerface.MsgRoomInfo", msgData)
    local msgPlayers = msgRoomUpdate.players

    -- 房间状态
    room.state = msgRoomUpdate.state
    logger.debug(" room update state = ", tostring(room.state))

    room.ownerID = msgRoomUpdate.ownerID
    room.roomNumber = msgRoomUpdate.roomNumber
    room.handStartted = msgRoomUpdate.handStartted

    --有人退出为 -1 有人进来为 1 没有变动为 0
    local updatePlayer = 0

    --logger.debug(" room handStartted ", room.handStartted)

    -- 显示房间号
    room.roomView:showRoomNumber()

    -- 首先看是否有player需要被删除
    local userID2Player = {}
    local player2Remove = {}
    for _, msgPlayer in ipairs(msgPlayers) do
        userID2Player[msgPlayer.userID] = msgPlayer
    end

    -- 记录需要被删除的玩家
    for _, player in pairs(room.players) do
        if userID2Player[player.userID] == nil or userID2Player[player.userID].chairID ~= player.chairID then
            table.insert(player2Remove, player)
        end
    end

    -- 删除已经离开的玩家，并隐藏其视图
    for _, player in ipairs(player2Remove) do
        --恢复椅子
        --room.roomView:restoreChair(player.playerView.viewChairID)

        room:removePlayer(player)
        player:unbindView()

        --有人出去
        updatePlayer = -1
    end
    -- 如果自己还没有创建，创建自己
    for _, msgPlayer in ipairs(msgPlayers) do
        local player = room:getPlayerByUserId(msgPlayer.userID)
        -- logger.debug(" room.userID:" .. room.user.userID .. ",msgPlayer userID:" .. msgPlayer.userID)
        if tostring(room.user.userID) == tostring(msgPlayer.userID) then
            if player == nil then
                room:createMyPlayer(msgPlayer)
                break
            elseif player.chairID ~= msgPlayer.chairID then
                room:removePlayer(player)
                player:unbindView()
                room:createMyPlayer(msgPlayer)
            end
        end
    end

    local me = room:me()
    local myOldState = me.state

    -- 更新，或者创建其他player
    for _, msgPlayer in ipairs(msgPlayers) do
        local player = room:getPlayerByUserId(msgPlayer.userID)
        if player == nil then
            room:createPlayerByInfo(msgPlayer)
            --有人进来或者更新，更新GPS
            if updatePlayer == 0 then
                updatePlayer = 1
            end
        else
            player:updateByPlayerInfo(msgPlayer)
        end
    end

    local roomStateEnum = proto.pokerface.RoomState
    local playerStateEnum = proto.pokerface.PlayerState

    --如果房间是等待状态，那么检查自己的状态是否已经是ready状态
    if msgRoomUpdate.state == roomStateEnum.SRoomWaiting then
        -- if updatePlayer ~= 0 then
        -- end
        if me.state ~= playerStateEnum.PSReady then
            -- 显示准备按钮，以便玩家可以点击
            room.roomView:show2ReadyButton()
        elseif myOldState ~= playerStateEnum.PSReady then
            -- 并隐藏to ready按钮
            room.roomView:hide2ReadyButton()
        end
    -- elseif msgRoomUpdate.state == roomStateEnum.SRoomPlaying then
    -- room.roomView:hideDistanceView()
    end

    --更新房间界面
    room.roomView:onUpdateStatus(msgRoomUpdate.state)
    room:hideDiscardedTips()

    --更新用户状态到视图
    local players = room.players
    for _, p in pairs(players) do
        local onUpdate = p.playerView.onUpdateStatus[p.state]
        onUpdate(room.state)
    end

    --保存牌局得分记录
    local scoreRecords = msgRoomUpdate.scoreRecords
    room.scoreRecords = scoreRecords
    if scoreRecords ~= nil and #scoreRecords > 0 then
        local totalScores = {}
        totalScores[1] = 0
        totalScores[2] = 0
        totalScores[3] = 0
        totalScores[4] = 0
        for i = 1, #scoreRecords do
            local playerRecords = scoreRecords[i].playerRecords
            for j = 1, 4 do
                local playerRecord = playerRecords[j]
                if playerRecord ~= nil then
                    local scoreNumber = playerRecord.score
                    local userID = playerRecord.userID
                    local player = room:getPlayerByUserId(userID)
                    totalScores[j] = totalScores[j] + scoreNumber
                    player.totalScores = totalScores[j]
                end
            end
        end
    end
    for _, player in pairs(room.players) do
        if player ~= nil and player.totalScores ~= nil then
            logger.debug(" 更新 player.totalScores ： ", player.totalScores)
        -- player.playerView:setGold(player.totalScores)
        end
    end
end
return Handler
