--[[
Description:
	LobbyError.lua 大厅错误码

Note:
	函数名，变量名以camel case风格命名。
	不允许全局变量。

	类名可以大写开头。
--]]
local proto = require "lobby/scripts/proto/proto"
local LobbyError = {
    [0] = "操作成功",
    [proto.lobby.MsgError.ErrDecode] = "解码错误",
    [proto.lobby.MsgError.ErrEncode] = "编码错误",
    [proto.lobby.MsgError.ErrNoRoomConfig] = "没有房间配置",
    [proto.lobby.MsgError.ErrDecodeRoomConfig] = "解码房间配置错误",
    [proto.lobby.MsgError.ErrDatabase] = "数据库错误",
    [proto.lobby.MsgError.ErrServerIsFull] = "服务器已经满",
    [proto.lobby.MsgError.ErrRequestGameServerTimeOut] = "请求游戏服务器超时",
    [proto.lobby.MsgError.ErrWaitGameServerSN] = "分配的序列号错误",
    [proto.lobby.MsgError.ErrRoomIDIsEmpty] = "房间ID为空",
    [proto.lobby.MsgError.ErrRoomNotExist] = "房间不存在",
    [proto.lobby.MsgError.ErrNotRoomCreater] = "你不是房间创建者",
    [proto.lobby.MsgError.ErrGameIsPlaying] = "游戏正在进行中",
    [proto.lobby.MsgError.ErrRoomCountIsOutOfLimit] = "房间数量已经达到上限",
    [proto.lobby.MsgError.ErrTokenIsEmpty] = "token为空",
    [proto.lobby.MsgError.ErrUserIdIsEmpty] = "用户ID为空",
    [proto.lobby.MsgError.ErrRoomNumberNotExist] = "你输入的房间号不存在，请确认",
    [proto.lobby.MsgError.ErrGameServerIDNotExist] = "游戏服务器ID不存在",
    [proto.lobby.MsgError.ErrRoomExist] = "房间已经存在",
    [proto.lobby.MsgError.ErrRoomNumberIsEmpty] = "房间号为空",
    [proto.lobby.MsgError.ErrRequestInvalidParam] = "请求的参数无效",
    [proto.lobby.MsgError.ErrTakeoffDiamondFailedNotEnough] = "剩余钻石不足",
    [proto.lobby.MsgError.ErrTakeoffDiamondFailedIO] = "数据库IO出错",
    [proto.lobby.MsgError.ErrTakeoffDiamondFailedRepeat] = "已经扣取钻石",
    [proto.lobby.MsgError.ErrGameServerUnsupportRoomType] = "游戏服务器不支持房间类型",
    [proto.lobby.MsgError.ErrGameServerRoomExist] = "游戏服务器已经存在这个房间",
    [proto.lobby.MsgError.ErrGameServerNoRoomConfig] = "游戏服务器没有房间配置",
    [proto.lobby.MsgError.ErrGameServerDecodeRoomConfig] = "游戏服务器解码房间配置错误",
    [proto.lobby.MsgError.ErrGameServerRoomNotExist] = "游戏服务器不存在这个房间",
    [proto.lobby.MsgError.ErrRoomIsFull] = "你输入的房间已满，无法加入",
    [proto.lobby.MsgError.ErrUserInBlacklist] = "你已经在黑名单中",
    [proto.lobby.MsgError.ErrUserCreateRoomLock] = "正在创建房间中，请稍等....",
    [proto.lobby.MsgError.ErrGenerateRoomNumber] = "生成房间号失败",
    [proto.lobby.MsgError.ErrIsNeedUpdate] = "生成房间号失败"
}

return LobbyError
