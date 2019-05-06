--[[
    一些用于和服务器通讯消息相关的辅助函数
]]
local protobuf = require "lobby/lcore/protobuf"
local logger = require "lobby/lcore/logger"

local PROTO = {}

local function loadProtofile()
    local pbfile = "scripts/proto/df.pb"
    logger.debug("begin to load protocolbuf descriptor file:", pbfile)

    local buffer = _ENV.thisMod.loader:LoadTextAsset(pbfile)
    protobuf.register(buffer)

    -- 下面这些代码是为了把枚举提取出来，放到PROTO表中方便访问
    -- 如果可以提前提取做成一个lua文件，就不需要下面这样提取了，只需要require
    -- 那个提前做好的lua文件就可以了
    local t = protobuf.decode("google.protobuf.FileDescriptorSet", buffer)
    for _, proto in ipairs(t.file) do
        --logger.debug("proto file:", proto.name, ", package:", proto.package)

        local packageEnumSet = PROTO[proto.package]
        if packageEnumSet == nil then
            packageEnumSet = {}
            PROTO[proto.package] = packageEnumSet
        end

        local enum = proto.enum_type

        for _, v in ipairs(enum) do
            local eset = {}
            packageEnumSet[v.name] = eset

            for _, v1 in ipairs(v.value) do
                --logger.debug("\t" , v1.name , "," , v1.number, ", t:", type(v1.number))
                eset[v1.name] = v1.number
            end
        end
    end
end

function PROTO.decodeMessage(t, msgData)
    return protobuf.decode(t, msgData)
end

function PROTO.encodeMessage(t, msgObj)
    return protobuf.encode(t, msgObj)
end

function PROTO.decodeGameMessage(msgData)
    return protobuf.decode("mahjong.GameMessage", msgData)
end

function PROTO.actionsHasAction(actions, action)
    return (actions & action) ~= 0
end

function PROTO.selectMeldFromMeldsForAction(meldsForAction, ty)
    local r = {}
    for _, m in ipairs(meldsForAction) do
        if m.meldType == ty then
            table.insert(r, m)
        end
    end

    return r
end

local enterRoomErrorMap = nil
function PROTO.getEnterRoomErrorCode(status)
    local mahjong = PROTO.mahjong.EnterRoomStatus
    if enterRoomErrorMap == nil then
        enterRoomErrorMap = {
            [mahjong.RoomNotExist] = "房间不存在",
            [mahjong.RoomIsFulled] = "你输入的房间已满，无法加入",
            [mahjong.RoomPlaying] = "房间正在游戏中",
            [mahjong.InAnotherRoom] = "您已经再另一个房间",
            [mahjong.MonkeyRoomUserIDNotMatch] = "测试房间userID不匹配",
            [mahjong.MonkeyRoomUserLoginSeqNotMatch] = "测试房间进入顺序不匹配",
            [mahjong.AppModuleNeedUpgrade] = "您的APP版本过老，请升级到最新版本",
            [mahjong.InRoomBlackList] = "您被房主踢出房间，10分钟内无法再次加入此房间",
            [mahjong.TakeoffDiamondFailedNotEnough] = "您的钻石不足，不能进入房间，请充值",
            [mahjong.TakeoffDiamondFailedIO] = "抱歉，系统扣除钻石失败，不能进入房间",
            [mahjong.RoomInApplicateDisband] = "房间正在解散"
        }
    end

    local msg = enterRoomErrorMap[status] or "未知错误"
    return msg
end

--加载pb文件
loadProtofile()

return PROTO
