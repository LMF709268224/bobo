local AgariIndex = {}

local logger = require "lobby/lcore/logger"
local proto = require "scripts/proto/proto"
local mahjong = proto.mahjong
local pokerfacerf = proto.mahjong
local agariTable = require "scripts/agariTable"

local slots = {}
local indexMap = {
    [mahjong.TileID.enumTid_MAN1] = "1", --万子
    [mahjong.TileID.enumTid_MAN2] = "2",
    [mahjong.TileID.enumTid_MAN3] = "3",
    [mahjong.TileID.enumTid_MAN4] = "4",
    [mahjong.TileID.enumTid_MAN5] = "5",
    [mahjong.TileID.enumTid_MAN6] = "6",
    [mahjong.TileID.enumTid_MAN7] = "7",
    [mahjong.TileID.enumTid_MAN8] = "8",
    [mahjong.TileID.enumTid_MAN9] = "9",
    [mahjong.TileID.enumTid_PIN1] = "21", --筒子
    [mahjong.TileID.enumTid_PIN2] = "22",
    [mahjong.TileID.enumTid_PIN3] = "23",
    [mahjong.TileID.enumTid_PIN4] = "24",
    [mahjong.TileID.enumTid_PIN5] = "25",
    [mahjong.TileID.enumTid_PIN6] = "26",
    [mahjong.TileID.enumTid_PIN7] = "27",
    [mahjong.TileID.enumTid_PIN8] = "28",
    [mahjong.TileID.enumTid_PIN9] = "29",
    [mahjong.TileID.enumTid_SOU1] = "11", --索子
    [mahjong.TileID.enumTid_SOU2] = "12",
    [mahjong.TileID.enumTid_SOU3] = "13",
    [mahjong.TileID.enumTid_SOU4] = "14",
    [mahjong.TileID.enumTid_SOU5] = "15",
    [mahjong.TileID.enumTid_SOU6] = "16",
    [mahjong.TileID.enumTid_SOU7] = "17",
    [mahjong.TileID.enumTid_SOU8] = "18",
    [mahjong.TileID.enumTid_SOU9] = "19",
    [mahjong.TileID.enumTid_TON] = "31", --东
    [mahjong.TileID.enumTid_NAN] = "32", --南
    [mahjong.TileID.enumTid_SHA] = "33", --西
    [mahjong.TileID.enumTid_PEI] = "34", --北
    [mahjong.TileID.enumTid_HAK] = "43", --白
    [mahjong.TileID.enumTid_HAT] = "42", --发
    [mahjong.TileID.enumTid_CHU] = "41", --中
    [mahjong.TileID.enumTid_PLUM] = "51", --梅
    [mahjong.TileID.enumTid_ORCHID] = "52", --兰
    [mahjong.TileID.enumTid_BAMBOO] = "53", --竹
    [mahjong.TileID.enumTid_CHRYSANTHEMUM] = "54",
    --菊
    [mahjong.TileID.enumTid_SPRING] = "55", --春
    [mahjong.TileID.enumTid_SUMMER] = "56", --夏
    [mahjong.TileID.enumTid_AUTUMN] = "57", --秋
    [mahjong.TileID.enumTid_WINTER] = "58" --冬
}

function AgariIndex.tileId2ArtId(tileID)
    local artId = indexMap[tileID]
    if artId == nil then
        logger.debug(" no art id for tile:" .. tileID)
    end

    return artId
end

----------------------------------
--克隆table
----------------------------------
local function stupidTableClone(src)
    local newX = {}
    for i, v in ipairs(src) do
        newX[i] = v
    end

    return newX
end

----------------------------------
--merge 'second' and 'first' to a new table
----------------------------------
local function stupidTableAddRange(first, second)
    local dst = first or {}
    for _, v in ipairs(second) do
        table.insert(dst, v)
    end
    return dst
end

----------------------------------
--重置slots
----------------------------------
local function resetSlots(hai)
    slots = {}
    for i = 1, 14 do
        slots[i] = 0
    end

    for _, v in ipairs(hai) do
        local idx = math.floor(v / 4)
        --logger.debug("resetSlots, idx:"..idx)
        local h = slots[idx + 1]
        slots[idx + 1] = h + 1
    end
end
----------------------------------
--计算牌组的key
----------------------------------
function AgariIndex.calcKey(hai)
    resetSlots(hai)

    local key = 0

    for i = 1, 14 do
        local s = slots[i]
        if s > 0 then
            --logger.debug("calcKey, s:"..s..",i:"..i)
            s = s << ((i - 1) * 3)
            --logger.debug("bit.blshift, s:"..s)
            key = key | s
        end
    end

    return key
end

----------------------------------
--转换为MsgCardHand，如果转换失败，返回nil
----------------------------------
function AgariIndex.agariConvertMsgCardHand(hai)
    local key = AgariIndex.calcKey(hai)
    local agari = agariTable[key]
    if agari == nil then
        --logger.debug("agariConvertMsgCardHand, nil agari, key:"..key)
        return nil
    end

    --var ct = (mahjong.CardHandType)(agari & 0x0f)
    -- local ct = bit.band(agari, 0x0f)
    local ct = agari & 0x0f
    local msgCardHand = {}
    msgCardHand.cardHandType = ct

    --排序，让大的牌在前面
    table.sort(
        hai,
        function(x, y)
            return y < x
        end
    )

    local cardsNew

    if ct == pokerfacerf.CardHandType.Flush then
        cardsNew = stupidTableClone(hai)
        --如果ACE绕过来，那需要把ACE放到屁股背后
        if 0 ~= agari & 0x0f then -- 0x0100 这个标志现在已经没了（table里面），所以现在不会绕回来
            local swp = cardsNew[1]
            table.remove(cardsNew, 1)
            table.insert(cardsNew, swp)
        end
    elseif ct == pokerfacerf.CardHandType.TripletPair or ct == pokerfacerf.CardHandType.Triplet2X2Pair then
        cardsNew = {}
        for _, v in ipairs(hai) do
            local idx = math.floor(v / 4)
            if slots[idx + 1] == 3 then
                table.insert(cardsNew, v)
            end
        end

        for _, v in ipairs(hai) do
            local idx = math.floor(v / 4)
            if slots[idx + 1] ~= 3 then
                table.insert(cardsNew, v)
            end
        end
    else
        cardsNew = stupidTableClone(hai)
    end

    --如果是黑桃梅花方块3，则转为炸弹
    msgCardHand.cards = cardsNew
    local count = 0
    for _, v in ipairs(cardsNew) do
        if math.floor(v / 4) == math.floor(mahjong.TileID.R3H / 4) and v ~= mahjong.TileID.R3H then
            count = count + 1
        end
    end

    if count == 3 then
        msgCardHand.cardHandType = pokerfacerf.CardHandType.Bomb
    end

    return msgCardHand
end

----------------------------------
--判断当前的手牌是否大于上一手牌
-- @param prevCardHand 上一手牌组
-- @param current 当前的牌组
----------------------------------
function AgariIndex.agariGreatThan(prevCardHand, current)
    -- 如果当前的是炸弹
    if current.cardHandType == pokerfacerf.CardHandType.Bomb then
        -- 上一手不是炸弹
        if prevCardHand.cardHandType ~= pokerfacerf.CardHandType.Bomb then
            return true
        end

        -- 上一手也是炸弹，则比较炸弹牌的大小，大丰关张不存在多于4个牌的炸弹
        return math.floor(current.cards[1] / 4) > math.floor(prevCardHand.cards[1] / 4)
    end

    -- 如果上一手牌是炸弹
    if (prevCardHand.cardHandType == pokerfacerf.CardHandType.Bomb) then
        return false
    end

    -- 必须类型匹配
    if (prevCardHand.cardHandType ~= current.cardHandType) then
        return false
    end

    -- 张数匹配
    if #(prevCardHand.cards) ~= #(current.cards) then
        return false
    end

    -- 单张时，2是最大的
    if prevCardHand.cardHandType == pokerfacerf.CardHandType.Single then
        if math.floor(prevCardHand.cards[1] / 4) == 0 then
            return false
        end

        if math.floor(current.cards[1] / 4) == 0 then
            return true
        end
    end

    -- 现在只比较最大牌的大小
    return math.floor(current.cards[1] / 4) > math.floor(prevCardHand.cards[1] / 4)
end
--寻找三个  或者三带二
-- local function searchUseableTripletOrTripletPair(hands)
--     local cardHands = {}
--     resetSlots(hands)

--     local right = math.floor(mahjong.AH / 4)
--     for newBombSuitID = 2, right + 1 do
--         local testBombRankID = newBombSuitID
--         local found = true
--         for i = 1, 2 do
--             if (slots[testBombRankID - i] < 3) then
--                 newBombSuitID = newBombSuitID + 1
--                 found = false
--                 break
--             end
--             if (found) then
--                 local cardHand = {}
--                 local xcards = AgariIndex.extractCardsByRank(hands, newBombSuitID, 3)
--                 cardHand.cards = xcards

--                 local left = newBombSuitID
--                 local right = newBombSuitID

--                 local pairCount = 0
--                 local pairAble = {}
--                 for testPair = 1, left do
--                     if (slots[testPair] > 1) then
--                         pairCount = pairCount + 1
--                         table.insert(pairAble, testPair)
--                     end
--                 end
--                 local job = math.floor(mahjong.JOB / 4)
--                 for testPair = right + 1, job do
--                     if (slots[testPair] > 1) then
--                         pairCount = pairCount + 1
--                         table.insert(pairAble, testPair)
--                     end
--                 end

--                 if (pairCount > 0) then
--                     -- 此处不再遍历各个对子
--                     local xcards = AgariIndex.extractCardsByRank(hands, pairAble[1], 2)
--                     table.insert(cardHand.cards, xcards)
--                 end
--                 table.insert(cardHands, cardHand)

--                 newBombSuitID = newBombSuitID + 1
--             end
--         end
--     end
--     return cardHands
-- end

--寻找单个
local function searchUseableSingle(hands)
    local cardHands = {}
    resetSlots(hands)
    local right = math.floor(mahjong.TileID.AH / 4)
    -- 找一个较大的单张
    for newBombSuitID = 1, right do
        if (slots[newBombSuitID + 1] > 0) then
            local cardHand = {}
            cardHand.cardHandType = pokerfacerf.CardHandType.Single
            local xcards = AgariIndex.extractCardsByRank(hands, newBombSuitID, 1)
            cardHand.cards = xcards
            table.insert(cardHands, cardHand)
        end
    end
    -- 自己有2，那就是最大
    if (slots[1] > 0) then
        local cardHand = {}
        cardHand.cardHandType = pokerfacerf.CardHandType.Single
        local xcards = AgariIndex.extractCardsByRank(hands, 0, 1)
        cardHand.cards = xcards
        table.insert(cardHands, cardHand)
    end
    return cardHands
end

--提示出牌
function AgariIndex.searchLongestDiscardCardHand(hands, specialCardID)
    table.sort(
        hands,
        function(x, y)
            return y < x
        end
    )
    local tt = {}

    -- tt = stupidTableAddRange(tt, searchLongestFlush(hands))
    -- tt = stupidTableAddRange(tt, searchLongestPairX(hands))
    -- tt = stupidTableAddRange(tt, searchLongestTriplet2XOrTriplet2X2Pair(hands))
    -- tt = stupidTableAddRange(tt, searchUseableTripletOrTripletPair(hands))
    tt = stupidTableAddRange(tt, searchUseableSingle(hands))

    --table.sort(tt, function(x,y) return #y.cards < #x.cards end)

    local needR3h = specialCardID >= 0
    if (needR3h) then
        for i = 1, #tt do
            for j = 1, (#tt[i].cards - 1) do
                if (tt[i].cards[j] == mahjong.TileID.R3H) then
                    return tt[i]
                end
            end
        end
    end
    --dump(tt , "--------------------------")
    return tt
end
----------------------------------
--寻找所有大于某一手牌的手牌
-- @param prev 上一手牌
-- @param hands 当前手上的牌
-- @param specialCardID 是否大于-1表示必须打出该张牌，
--    或者包含该张牌的牌组，注意目前只有红桃2的情况，
--    如果指定要打出红桃2则只返回一个红桃2的牌组
----------------------------------
function AgariIndex.findAllGreatThanCardHands(prev, hands, specialCardID)
    local prevCT = prev.cardHandType
    local isBomb = false
    local tt = {}

    if specialCardID >= 0 then
        local cardHand = {}
        cardHand.cardHandType = pokerfacerf.CardHandType.Single
        --目前这种情况只有红桃2，也即是rank == 0
        cardHand.cards = AgariIndex.extractCardsByRank(hands, 0, 1)
        table.insert(tt, cardHand)
        return tt
    end

    if prevCT == pokerfacerf.CardHandType.Bomb then
        isBomb = true
    end

    local fnMaps = {
        [pokerfacerf.CardHandType.Bomb] = function(prev2, hands2)
            return AgariIndex.findBombGreatThan(prev2, hands2)
        end,
        [pokerfacerf.CardHandType.Flush] = function(prev2, hands2)
            ---修改
            return AgariIndex.findFlushGreatThan(prev2, hands2)
        end,
        [pokerfacerf.CardHandType.Single] = function(prev2, hands2)
            return AgariIndex.findSingleGreatThan(prev2, hands2)
        end,
        [pokerfacerf.CardHandType.Pair] = function(prev2, hands2)
            return AgariIndex.findPairGreatThan(prev2, hands2)
        end,
        [pokerfacerf.CardHandType.Pair2X] = function(prev2, hands2)
            return AgariIndex.findPair2XGreatThan(prev2, hands2)
        end,
        [pokerfacerf.CardHandType.Triplet] = function(prev2, hands2)
            return AgariIndex.findTripletGreatThan(prev2, hands2)
        end,
        [pokerfacerf.CardHandType.Triplet2X] = function(prev2, hands2)
            return AgariIndex.findTriplet2XGreatThan(prev2, hands2)
        end,
        [pokerfacerf.CardHandType.Triplet2X2Pair] = function(prev2, hands2)
            ---修改
            return AgariIndex.findTriplet2X2PairGreatThan(prev2, hands2)
        end,
        [pokerfacerf.CardHandType.TripletPair] = function(prev2, hands2)
            return AgariIndex.findTripletPairGreatThan(prev2, hands2)
        end
    }

    local fn = fnMaps[prevCT]
    tt = fn(prev, hands)

    if not isBomb then
        local tt2 = AgariIndex.findBomb(hands)
        tt = stupidTableAddRange(tt, tt2)
    end

    return tt
end

----------------------------------
--从手牌上寻找炸弹
----------------------------------
function AgariIndex.findBomb(hands)
    local cardHands = {}
    resetSlots(hands)

    local right = math.floor(mahjong.TileID.AH / 4)
    --跳过2和3，因为四个3是非法牌型
    for newBombSuitID = 2, right do
        if slots[newBombSuitID + 1] > 3 then
            local cardHand = {}
            cardHand.cardHandType = pokerfacerf.CardHandType.Bomb
            cardHand.cards = AgariIndex.extractCardsByRank(hands, newBombSuitID, 4)
            table.insert(cardHands, cardHand)
        end
    end

    -- 如果有3个ACE，也是炸弹
    local aceRank = math.floor(mahjong.TileID.AH / 4)
    if (slots[aceRank + 1] > 2) then
        local cardHand = {}
        cardHand.cardHandType = pokerfacerf.CardHandType.Bomb
        cardHand.cards = AgariIndex.extractCardsByRank(hands, aceRank, 4)
        table.insert(cardHands, cardHand)
    end

    -- 如果手上还有三张3，也算是炸弹，而且不算红桃3
    local r3Rank = math.floor(mahjong.TileID.R3H / 4)
    if (slots[r3Rank + 1] > 2) then
        local cards = {}
        for _, v in ipairs(hands) do
            if math.floor(v / 4) == r3Rank and v ~= mahjong.TileID.R3H then
                table.insert(cards, v)
            end
        end

        if #cards == 3 then
            local cardHand = {}
            cardHand.cardHandType = pokerfacerf.CardHandType.Bomb
            cardHand.cards = cards
            table.insert(cardHands, cardHand)
        end
    end

    return cardHands
end
----------------------------------
--寻找所有大于上一手"连3张+两对子"的有效组合
----------------------------------
function AgariIndex.findTriplet2X2PairGreatThan(prev, hands)
    local cardHands = {}
    resetSlots(hands)

    local seqLength = #prev.cards / 5 -- #prev.cards - 4 -- 减去2个对子
    local bombCardRankID = math.floor(prev.cards[1] / 4)
    local rightMost = math.floor(mahjong.TileID.AH / 4)
    local newBombSuitID = bombCardRankID + 1

    while newBombSuitID <= rightMost do
        local testBombRankID = newBombSuitID
        local found = true
        for i = 1, seqLength do
            if slots[testBombRankID - i + 2] < 3 then
                newBombSuitID = newBombSuitID + 1

                found = false
                break
            end
        end
        -- 找到了
        if found then
            local left = newBombSuitID + 1 - seqLength
            local right = newBombSuitID

            local pairCount = 0
            local pairAble = {}
            for testPair = 1, (left - 1) do
                if (slots[testPair + 1] > 1) then
                    pairCount = pairCount + 1
                    table.insert(pairAble, testPair)
                end
            end

            local uppon = math.floor(mahjong.TileID.AH / 4)
            for testPair = right + 1, uppon do
                if (slots[testPair + 1] > 1) then
                    pairCount = pairCount + 1
                    table.insert(pairAble, testPair)
                end
            end

            if (pairCount >= seqLength) then
                -- 此处不在遍历各种对子组合
                local cardHand = {}
                cardHand.cardHandType = pokerfacerf.CardHandType.Triplet2X2Pair

                local xcards = AgariIndex.extractCardsByRanks(hands, left, right, 3)
                cardHand.cards = stupidTableAddRange(cardHand.cards, xcards)

                for kk, pp in ipairs(pairAble) do
                    xcards = AgariIndex.extractCardsByRank(hands, pp, 2)
                    cardHand.cards = stupidTableAddRange(cardHand.cards, xcards)
                    if (kk == seqLength) then
                        break
                    end
                end

                table.insert(cardHands, cardHand)
            end

            newBombSuitID = newBombSuitID + 1
        end
    end

    return cardHands
end
----------------------------------
--寻找所有大于上一手"3张+对子"的有效组合
----------------------------------
function AgariIndex.findTripletPairGreatThan(prev, hands)
    local cardHands = {}
    resetSlots(hands)

    local flushLen = #prev.cards - 2 --减去对子
    local bombCardRankID = math.floor(prev.cards[1] / 4)
    local seqLength = math.floor(flushLen / 3)
    local newBombSuitID = bombCardRankID + 1
    local rightMost = math.floor(mahjong.TileID.AH / 4)
    while newBombSuitID <= rightMost do
        local testBombRankID = newBombSuitID
        local found = true
        for i = 1, seqLength do
            if (slots[testBombRankID - i + 2] < 3) then
                newBombSuitID = newBombSuitID + 1
                found = false
                break
            end
        end

        -- 找到了
        if (found) then
            local left = newBombSuitID + 1 - seqLength
            local right = newBombSuitID

            local pairCount = 0
            local pairAble = {}
            for testPair = 0, left - 1 do
                if (slots[testPair + 1] > 1) then
                    pairCount = pairCount + 1
                    table.insert(pairAble, testPair)
                end
            end

            local uppon = math.floor(mahjong.TileID.AH / 4)
            for testPair = right + 1, uppon do
                if (slots[testPair + 1] > 1) then
                    pairCount = pairCount + 1
                    table.insert(pairAble, testPair)
                end
            end

            if (pairCount > 0) then
                -- 此处不再遍历各个对子
                local cardHand = {}
                cardHand.cardHandType = pokerfacerf.CardHandType.TripletPair
                local xcards = AgariIndex.extractCardsByRank(hands, left, 3)
                cardHand.cards = stupidTableAddRange(cardHand.cards, xcards)
                xcards = AgariIndex.extractCardsByRank(hands, pairAble[1], 2)
                cardHand.cards = stupidTableAddRange(cardHand.cards, xcards)
                table.insert(cardHands, cardHand)
            end

            newBombSuitID = newBombSuitID + 1
        end
    end

    return cardHands
end

----------------------------------
--寻找所有大于上一手"3张"的有效组合
----------------------------------
function AgariIndex.findTripletGreatThan(prev, hands)
    local cardHands = {}
    resetSlots(hands)

    local bombCardRankID = math.floor(prev.cards[1] / 4)
    local rightMost = math.floor(mahjong.TileID.AH / 4)
    -- 找一个较大的三张
    for newBombSuitID = bombCardRankID + 1, rightMost do
        if (slots[newBombSuitID + 1] > 2) then
            local cardHand = {}
            cardHand.cardHandType = pokerfacerf.CardHandType.Triplet
            local xcards = AgariIndex.extractCardsByRank(hands, newBombSuitID, 3)
            cardHand.cards = xcards
            table.insert(cardHands, cardHand)
        end
    end

    return cardHands
end

----------------------------------
--寻找所有大于上一手"连3张"的有效组合
----------------------------------
function AgariIndex.findTriplet2XGreatThan(prev, hands)
    local cardHands = {}
    resetSlots(hands)

    local flushLen = #prev.cards
    local bombCardRankID = math.floor(prev.cards[1] / 4) -- 最大的顺子牌rank
    local seqLength = math.floor(flushLen / 3)
    local newBombSuitID = bombCardRankID + 1
    local rightMost = math.floor(mahjong.TileID.AH / 4)
    while newBombSuitID <= rightMost do
        local testBombRankID = newBombSuitID
        local found = true
        for i = 1, seqLength do
            if (slots[testBombRankID - i + 2] < 3) then
                newBombSuitID = newBombSuitID + 1
                found = false
                break
            end
        end

        -- 找到了
        if (found) then
            local cardHand = {}
            cardHand.cardHandType = pokerfacerf.CardHandType.Triplet2X
            local xcards = AgariIndex.extractCardsByRanks(hands, testBombRankID - seqLength + 1, testBombRankID, 3)
            cardHand.cards = xcards
            table.insert(cardHands, cardHand)

            newBombSuitID = newBombSuitID + 1
        end
    end

    return cardHands
end

----------------------------------
--寻找所有大于上一手"连对"的有效组合
----------------------------------
function AgariIndex.findPair2XGreatThan(prev, hands)
    local cardHands = {}
    resetSlots(hands)

    local flushLen = #prev.cards
    local bombCardRankID = math.floor(prev.cards[1] / 4) -- 最大的顺子牌rank
    local seqLength = math.floor(flushLen / 2)
    local newBombSuitID = bombCardRankID + 1
    local rightMost = math.floor(mahjong.TileID.AH / 4)
    while newBombSuitID <= rightMost do
        local testBombRankID = newBombSuitID
        local found = true
        for i = 1, seqLength do
            if (slots[testBombRankID - i + 2] < 2) then
                newBombSuitID = newBombSuitID + 1

                found = false
                break
            end
        end

        -- 找到了
        if (found) then
            local cardHand = {}
            cardHand.cardHandType = pokerfacerf.CardHandType.Pair2X
            local xcards = AgariIndex.extractCardsByRanks(hands, testBombRankID - seqLength + 1, testBombRankID, 2)
            cardHand.cards = xcards

            table.insert(cardHands, cardHand)
            newBombSuitID = newBombSuitID + 1
        end
    end

    return cardHands
end

----------------------------------
--寻找所有大于上一手"对子"的有效组合
----------------------------------
function AgariIndex.findPairGreatThan(prev, hands)
    local cardHands = {}
    resetSlots(hands)

    local bombCardRankID = math.floor(prev.cards[1] / 4)

    -- 找一个较大的对子
    local rightMost = math.floor(mahjong.TileID.AH / 4)
    for newBombSuitID = bombCardRankID + 1, rightMost do
        if (slots[newBombSuitID + 1] > 1) then
            local cardHand = {}
            cardHand.cardHandType = pokerfacerf.CardHandType.Pair
            local xcards = AgariIndex.extractCardsByRank(hands, newBombSuitID, 2)
            cardHand.cards = xcards
            table.insert(cardHands, cardHand)
        end
    end

    return cardHands
end

----------------------------------
--寻找所有大于上一手"单张"的有效组合
----------------------------------
function AgariIndex.findSingleGreatThan(prev, hands)
    local cardHands = {}
    resetSlots(hands)

    local bombCardRankID = math.floor(prev.cards[1] / 4)
    if (bombCardRankID == 0) then
        -- 2已经是最大的单张了
        return cardHands
    end

    -- 找一个较大的单张
    local rightMost = math.floor(mahjong.TileID.AH / 4)
    local newBombSuitID = bombCardRankID + 1
    while newBombSuitID <= rightMost do
        if (slots[newBombSuitID + 1] > 0) then
            local cardHand = {}
            cardHand.cardHandType = pokerfacerf.CardHandType.Single
            local xcards = AgariIndex.extractCardsByRank(hands, newBombSuitID, 1)
            cardHand.cards = xcards
            table.insert(cardHands, cardHand)
        end

        newBombSuitID = newBombSuitID + 1
    end

    --自己有2，那就是最大
    if (slots[1] > 0) then
        local cardHand = {}
        cardHand.cardHandType = pokerfacerf.CardHandType.Single
        local xcards = AgariIndex.extractCardsByRank(hands, 0, 1)
        cardHand.cards = xcards
        table.insert(cardHands, cardHand)
    end

    return cardHands
end

----------------------------------
--寻找所有大于上一手"顺子"的有效组合
----------------------------------
function AgariIndex.findFlushGreatThan(prev, hands)
    local cardHands = {}
    resetSlots(hands)

    local flushLen = #prev.cards
    local bombCardRankID = math.floor(prev.cards[1] / 4) -- 最大的顺子牌rank
    local seqLength = flushLen
    local newBombSuitID = bombCardRankID + 1
    local rightMost = math.floor(mahjong.TileID.AH / 4) -- AH 改为 R3H  20180201 mufan
    while newBombSuitID <= rightMost do
        local testBombRankID = newBombSuitID
        local found = true
        for i = 1, seqLength do
            if slots[testBombRankID - i + 2] < 1 then
                newBombSuitID = newBombSuitID + 1
                found = false

                break
            end
        end

        -- 找到了
        if (found) then
            local cardHand = {}
            cardHand.cardHandType = pokerfacerf.CardHandType.Flush
            local xcards = AgariIndex.extractCardsByRanks(hands, testBombRankID - seqLength + 1, testBombRankID, 1)
            cardHand.cards = xcards
            table.insert(cardHands, cardHand)

            newBombSuitID = newBombSuitID + 1
        end
    end

    return cardHands
end

----------------------------------
--寻找所有大于上一手"炸弹"的有效组合
----------------------------------
function AgariIndex.findBombGreatThan(prev, hands)
    -- 注意不需要考虑333这种炸弹，因为他是最小的，
    -- 而现在是寻找一个大于某个炸弹的炸弹
    local cardHands = {}
    resetSlots(hands)

    local bombCardRankID = math.floor(prev.cards[1] / 4)
    local rightMost = math.floor(mahjong.TileID.AH / 4)
    --4张的是炸弹
    for newBombSuitID = bombCardRankID + 1, rightMost do
        if (slots[newBombSuitID + 1] > 3) then
            local cardHand = {}
            cardHand.cardHandType = pokerfacerf.CardHandType.Bomb
            local xcards = AgariIndex.extractCardsByRank(hands, newBombSuitID, 4)
            cardHand.cards = xcards
            table.insert(cardHands, cardHand)
        end
    end

    -- 如果有3个ACE，也是炸弹
    if (slots[rightMost + 1] > 2) then
        local cardHand = {}
        cardHand.cardHandType = pokerfacerf.CardHandType.Bomb
        local xcards = AgariIndex.extractCardsByRank(hands, rightMost, 4)
        cardHand.cards = xcards
        table.insert(cardHands, cardHand)
    end

    return cardHands
end

----------------------------------
--从手牌上根据rank抽取若干张牌到一个新table中
----------------------------------
function AgariIndex.extractCardsByRank(hands, rank, count)
    logger.debug("extractCardsByRank, rank:", rank, ",count:", count)
    local extract = {}
    local ecount = 0
    for _, h in ipairs(hands) do
        if math.floor(h / 4) == rank then
            table.insert(extract, h)
            ecount = ecount + 1
            if ecount == count then
                break
            end
        end
    end

    return extract
end

----------------------------------
--从手牌上根据rank范围抽取若干张牌到一个新table中
----------------------------------
function AgariIndex.extractCardsByRanks(hands, rankStart, rankStop, count)
    logger.debug("extractCardsByRanks, rankStart:", rankStart, ",rankStop:", rankStop, ",count:", count)
    local extract = {}

    for rank = rankStart, rankStop do
        local ecount = 0
        for _, h in ipairs(hands) do
            if math.floor(h / 4) == rank then
                table.insert(extract, h)
                ecount = ecount + 1
                if ecount == count then
                    break
                end
            end
        end
    end

    return extract
end

return AgariIndex
