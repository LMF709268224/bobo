local DFConfig = {}

--资源路径
DFConfig.PATH = {
	EFFECTS = "GameModule/GuanZhang/_AssetsBundleRes/dfEffects/",
	EFFECTS_GZ = "GameModule/GuanZhang/_AssetsBundleRes/gzEffects/",
	EFFECTS_OLD = "GameModule/GuanZhang/_AssetsBundleRes/effects/"
}

--特效
DFConfig.EFF_DEFINE = {
	SUB_TOUZI_NAME = "Effects_touzi_0", --骰子前缀
	SUB_SHUIPAO = "Effects_shuipao",
	SUB_DRAGCARDEFF = "Effects_tuodong",
	 --拖动牌
	--结算界面
	SUB_DAYINGJIA = "Effects_jiemian_dayingjia", --大赢家
	SUB_JIEMIAN_HUANGZHUANG = "Effects_jiemian_pingjv", --平局
	SUB_PAIJVZONGJIESUAN = "Effects_jiemian_zongjiesuan", --牌局总结算
	SUB_JIEMIAN_SHU = "Effects_jiemian_shibai", --失败
	SUB_JIEMIAN_YING = "Effects_jiemian_shengli", --胜利
	SUB_JIEMIAN_WIN = "Effects_jiemian_huosheng", --获胜标志
	SUB_JIEMIAN_DUIJUKAISHI = "Effects_jiemian_duijukaishi", --对局开始
	--关张
	SUB_GUANZHANG_HANG = "Effects_zi_hang_FeiJi", --夯加飞机
	SUB_GUANZHANG_LIANDUI = "Effects_zi_liandui", --连对
	SUB_GUANZHANG_SANDAIER = "Effects_zi_sandaier", --三带二
	SUB_GUANZHANG_SANLIANDUI = "Effects_zi_sanliandui", --飞机
	SUB_GUANZHANG_SHUNZI = "Effects_zi_shunzi", --顺子
	SUB_GUANZHANG_ZHADAN = "Effects_zi_zhadan", --炸弹
	SUB_GUANZHANG_BUYAO = "Effects_zi_buyao", --不要
	SUB_GUANZHANG_JINGLING = "Effects_zi_jingling" --剩牌告警动画
}

--动画播放时间
DFConfig.ANITIME_DEFINE = {
	HANDCARDFLYLONGTIME = 0.4,
	 --长距离移牌
	HANDCARDFLYSHORTTIME = 0.2,
	 --短距离移牌
	DELAYPLAYDICEANITIME = 2,
	 --延迟播放骰子动画
	DELAYSHOWOVERUITIME = 5,
	 --延迟多久播放结算界面
	SAIZIPLAYTIME = 2,
	 --骰子动画播放多久
	OUTCARDTIPSHOWTIME = 0.7,
	 --出牌展示框显示多久
	FAPAIANIPLAYTIME = 1,
	 --发牌动画播放多久
	CHATQIPAOSHOWTIME = 2
 --聊天汽泡显示多久
}

--聊天
DFConfig.CHATCOMMONSPEAK_DEFINE = {
	[1] = "你手气",
	[2] = "快点儿吧",
	[3] = "谁出一个",
	[4] = "你这小屁胡",
	[5] = "嗨",
	[6] = "想要的牌",
	[7] = "来来来",
	[8] = "今天赢",
	[9] = "你家是开",
	[10] = "这牌",
	[11] = "能让我"
}

--定义字符串
DFConfig.STR_DEFINE = {
	SUB_STR_LZMJ = "大丰麻将 ",
	SUB_STR_JUSU = " 局数 ",
	SUB_STR_MAPAISU = " 马牌数 ",
	SUB_STR_NUJUSANFEN = " 流局算分 ",
	SUB_STR_NUJUBUSANFEN = " 流局不算分 ",
	SUB_STR_YOUFENPAI = " 有风牌 ",
	SUB_STR_WUFENPAI = " 无风牌 ",
	SUB_STR_BAIBAN = " 白板 ",
	SUB_STR_FANGUI = " 翻鬼 ",
	SUB_STR_SHENGYU = "剩余",
	SUB_STR_ZHANG = "张",
	SUB_STR_DI = "  第",
	SUB_STR_JU = "局",
	SUB_STR_SHIFENEXITGAME = "是否退出房间？",
	SUB_STR_EXITGAMEWILLTUGAN = "离开游戏将被托管，是否退出游戏？",
	SUB_STR_CHECKWIFI = "连接游戏失败，请检查您的网络！",
	SUB_STR_ROOMID = "房间号:",
	SUB_STR_LISTENFAN = "倍",
	SUB_STR_LISTENZHANG = "张"
}

DFConfig.RoomTips = {
	"温馨提示：牌局未开始前，房主可点击其他用户头像踢出不认识的人哦！",
	"温馨提示：勾选‘购买时不再提示’，对其他人使用钻石道具可直接使用。",
	"温馨提示：牌局未打完，解散房间，系统会返还未打牌局的钻石。",
	"温馨提示：如果打牌感觉卡顿，可看牌局内左上角网络信号是否稳定。",
	"温馨提示：在大厅点击钻石旁边的+号，可前往商城购买钻石。",
	"温馨提示：与朋友家人组牌局群，将房间分享到微信，约局打牌更方便。",
	"温馨提示：绑定好友的推广码，能获得免费钻石哦！",
	"温馨提示：每日首次在大厅分享游戏，可获得免费钻石哦！",
	"温馨提示：在商城绑定代理推广码，购买钻石会额外多送哦！",
	"温馨提示：在牌局内的设置里可更改桌布颜色和麻将颜色！",
	"温馨提示：GPS定位准确性在100米范围内。",
	"温馨提示：关注“闲雅大丰牌牌乐”公众号，可获取最新最全的游戏福利！",
	"温馨提示：可以通过滑动或双击麻将打出您想出的牌。",
	"温馨提示：点击加入房间，输入好友的房号，可进入对应房间。",
	"温馨提示：文明游戏，禁止辱骂，良好的游戏行为能给您带来更多的朋友！",
	"温馨提示：切勿相信外挂售卖等虚假信息，谨防上当受骗，本游戏绝无外挂！",
	"温馨提示：若您遇到游戏问题，可在大厅点击客服，点击‘仅发送错误报告’。"
}

--错误提示 （关张）
DFConfig.ErrorInRoom = {
	ERR_ROOM_NOTSKIP = "玩家已经报警，您不能跳过", --灰色的过按钮 提示文字
	ERR_ROOM_NOTSKIP_2 = "轮到您出牌，您不能跳过", --灰色的过按钮 提示文字
	ERR_ROOM_NOTDISCARDS = "您没有可出的牌", --灰色的出牌按钮  提示文字
	ERR_ROOM_CARDSNOTDIS = "您选择的牌不能同时出", --比如，选了34 这样不可以出的牌
	ERR_ROOM_NOTSELECTCARDS = "请选择牌", --玩家未选择牌，就点击出牌
	ERR_ROOM_NOTDISCARDSR3H = "请选择带有红桃3的牌", --开局有红桃3 必出红桃3
	ERR_ROOM_NOTDISCARDSR2H = "您只能出红桃2", --别人出了A 你有2的话 只能出2
	ERR_ROOM_DISCARDISSMALL = "您的牌不够大" --  不够大的，不能压上家
}

DFConfig.CommonLanguage = {
	"哎哎哎 别擦鸭子 快点子",
	"把你们等晚了不好意思啊",
	"情况不明 对子朝前",
	"帅哥 美女你来好啊",
	"随你打的精如鬼 都比不上我的飞毛腿",
	"天不亮 都不准走啊"
}

return DFConfig
