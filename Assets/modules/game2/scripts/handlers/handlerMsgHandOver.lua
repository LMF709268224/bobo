--[[
    处理服务器下发的一手牌结束的消息
    一手牌结束后分数结算
]]
local Handler = {}
Handler.VERSION = "1.0"
local proto = require "scripts/proto/proto"

function Handler.onMsg(msgData, room)
    --print('llwant hand over msg')
    --TODO:关闭倒计时
    room.roomView:stopDiscardCountdown()
    room:hideDiscardedTips()

    local msgHandOver = proto.decodeMessage("mahjong.MsgHandOver", msgData)
    -- msgHandOver:ParseFromString(msgData)
    --把结果保存到 room
    room.msgHandOver = msgHandOver
    local playerTileLists = msgHandOver.playerTileLists
    for _, v in ipairs(playerTileLists) do
        local playerTileList = v
        local chairID = v.chairID
        local player = room:getPlayerByChairID(chairID)

        --填充手牌列表,自身手牌列表重置
        --其他玩家之前并没有手牌列表，因此需要新建一个
        player.tilesHand = {}
        player:addHandTiles(playerTileList.tilesHand)

        --重置面子牌列表
        --填充面子牌列表
        player.melds = {}
        player:addMelds(playerTileList.melds)

        --player.playerTileList = playerTileList
    end

    --TODO:重置操作面板，重置等待玩家等等
    room.roomView:clearWaitingPlayer()
    --隐藏操作按钮
    local myPlayer = room.myPlayer
    myPlayer.playerView:hideOperationButtons()

    --所有人的手牌，都排一下序
    --重新显示各个玩家的手牌，全部明牌显示
    local players = room.players
    for _, p in pairs(players) do
        p.lastTile = p.tilesHand[#p.tilesHand] --保存最后一张牌，可能是胡牌。。。用于最后结算显示
        p:sortHands()
        --摊开手牌
        p:hand2Exposed()
    end

    Handler.onHandOver(msgHandOver, room)
end

function Handler.onHandOver(msgHandOver, room)
    -- local win = false

    -- 隐藏游戏内聊天面板
    local mjproto = proto.mahjong.HandOverType
    if msgHandOver.endType ~= mjproto.enumHandOverType_None then
        --胡，放铳效果直接挂在playerView上
        -- local myself = room.myPlayer
        for _, score in ipairs(msgHandOver.scores.playerScores) do
            local player = room:getPlayerByChairID(score.targetChairID)
            if score.winType == mjproto.enumHandOverType_Win_SelfDrawn then
                player:playZiMoAnimation()
            elseif score.winType == mjproto.enumHandOverType_Chucker then
                --点炮,没有点炮的音效
                player:playDianPaoAnimation()
            elseif score.winType == mjproto.enumHandOverType_Win_Chuck then
                --吃铳
                player:playChiChongAnimation()
            end
            -- if player == myself then
            -- win = score.score >= 0
            -- end
            player.score = score
        end
    end

    -- local soundName
    -- if msgHandOver.endType == mjproto.enumHandOverType_None then
    --     soundName = "effect_huangzhuang"
    -- elseif win then
    --     soundName = "effect_win"
    -- else
    --     soundName = "effect_lost"
    -- end

    --播放声音
    -- dfCompatibleAPI:soundPlay("effect/" .. soundName)

    --本局结束动画（现在是特效，是一个需要等待的特效）
    -- room.roomView:handOverAnimation()

    --显示手牌输赢结果
    room:loadHandResultView()
end
return Handler
