--[[
    处理服务器下发的发牌消息，发牌消息意味一手牌开始
]]
local Handler = {}
Handler.VERSION = "1.0"
local proto = require "scripts/proto/proto"

function Handler.onMsg(msgData, room)
    print("llwant, deal msg")

    local msgDeal = proto.decodeMessage("mahjong.MsgDeal", msgData)
    -- msgDeal:ParseFromString(msgData)
    --清理
    room:resetForNewHand()

    --隐藏gps
    -- room.roomView.distanceView.visible = false

    --保存一些房间属性
    room.bankerChairID = msgDeal.bankerChairID
    --是否连庄
    room.isContinuousBanker = msgDeal.isContinuousBanker
    room.windFlowerID = msgDeal.windFlowerID
    room.tilesInWall = msgDeal.tilesInWall
    --大丰 1：就表示家家庄    -- 盐城 >0 表示加价局计数
    --print("llwant,msgDeal.markup : " .. msgDeal.markup)
    room.markup = msgDeal.markup
    --print("llwant,handlerMsgRestore ---------------"..tostring(msgDeal.markup))
    room:updateTilesInWallUI()

    local players = room.players
    --隐藏复制按钮
    --room.roomView.copyRoomNumber.visible = false
    --对局开始动画
    room.roomView:gameStartAnimation()
    --TODO: 播放投色子动画
    -- room.roomView:touZiStartAnimation(msgDeal.dice1, msgDeal.dice2)
    --TODO:修改家家庄标志
    room.roomView:setJiaJiaZhuang()
    --根据风圈修改
    room.roomView:setRoundMask(1)
    --修改庄家标志
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
    end

    --播放发牌动画，并使用coroutine等待动画完成
    -- room.roomView:dealAnimation()

    --等待庄家出牌
    local bankerPlayer = room:getPlayerByChairID(room.bankerChairID)
    room.roomView:setWaitingPlayer(bankerPlayer)

    --自己手牌排一下序
    local mySelf = room:me()
    mySelf:sortHands(mySelf == bankerPlayer)

    --显示各个玩家的手牌（对手只显示暗牌）和花牌
    for _, p in pairs(players) do
        print("llwant, 显示各个玩家的手牌")
        p:hand2UI()
        p:flower2UI()
    end
end

return Handler
