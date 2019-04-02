--[[
    处理服务器下发的一手牌结束的消息
    一手牌结束后分数结算
]]
local Handler = {}
Handler.VERSION = "1.0"

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

function Handler.onMsg(msgData, room)
    logger.debug("llwant hand over msg")
    --TODO:关闭倒计时
    room:stopDiscardCountdown()
    room:hideDiscardedTips()

    local msgHandOver = proto.decodeMessage("pokerface.MsgHandOver", msgData)

    --把结果保存到 room
    room.msgHandOver = msgHandOver
    local playerCardLists = msgHandOver.playerCardLists
    for _, v in ipairs(playerCardLists) do
        local playerTileList = v
        local chairID = v.chairID
        local player = room:getPlayerByChairID(chairID)

        --填充手牌列表,自身手牌列表重置
        --其他玩家之前并没有手牌列表，因此需要新建一个
        player.cardsOnHand = {}
        player:addHandTiles(playerTileList.cardsOnHand)

        --重置面子牌列表
        --填充面子牌列表
        --player.melds = {}
        --player:addMelds(playerTileList.melds)

        --player.playerTileList = playerTileList
    end

    --TODO:重置操作面板，重置等待玩家等等
    room.roomView:clearWaitingPlayer()
    --隐藏操作按钮
    local myPlayer = room:me()
    myPlayer.playerView:hideOperationButtons()

    --所有人的手牌，都排一下序
    --重新显示各个玩家的手牌，全部明牌显示
    local players = room.players
    for _, p in pairs(players) do
        p.lastTile = p.cardsOnHand[#p.cardsOnHand] --保存最后一张牌，可能是胡牌。。。用于最后结算显示
        p:sortHands()
        --摊开手牌
        --p:hand2Exposed()
    end

    Handler.onHandOver(msgHandOver, room)
end

function Handler.onHandOver(msgHandOver, room)
    local win = false

    -- 隐藏游戏内聊天面板
    room.roomView:hideChatPanel()

    if msgHandOver.endType ~= proto.prunfast.HandOverType.enumHandOverType_None then
        local myself = room:me()
        for _, score in ipairs(msgHandOver.scores.playerScores) do
            local player = room:getPlayerByChairID(score.targetChairID)
            if player == myself then
                win = score.score >= 0
            end
            player.score = score
        end
    end

    local soundName
    if msgHandOver.endType == proto.prunfast.HandOverType.enumHandOverType_None then
        soundName = "effect_huangzhuang"
    elseif win then
        soundName = "effect_win"
    else
        soundName = "effect_lost"
    end

    room:resumeBackMusicVolume(0)

    logger.debug("onHandOver sound name:", soundName)
    --播放声音
    --dfCompatibleAPI:soundPlay("effect/" .. soundName)

    room.roomView.unityViewNode:DelayRun(
        3,
        function()
            room:resumeBackMusicVolume()
        end
    )
    --本局结束动画（现在是特效，是一个需要等待的特效）
    room.roomView:handOverAnimation()

    --显示手牌输赢结果
    room:loadHandResultView()
end
return Handler
