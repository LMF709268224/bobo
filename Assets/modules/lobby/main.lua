local logger = require "lobby/lcore/logger"
local lenv = require "lobby/lenv"
local fairy = require "lobby/lcore/fairygui"
local CS = _ENV.CS

logger.warn("lobby main startup")

-- 打印所有被C#引用着的LUA函数
local function print_func_ref_by_csharp()
	local registry = debug.getregistry()
	for k, v in pairs(registry) do
		if type(k) == "number" and type(v) == "function" and registry[v] == k then
			local info = debug.getinfo(v)
			print(string.format("%s:%d", info.short_src, info.linedefined))
		end
	end
end

-- 由C#调用
local function shutdownCleanup()
	logger.warn("lobby main cleanup")
	print_func_ref_by_csharp()
end

-- 下面这段字符串代码主要是给c#里面执行
-- 每次新建一个子游戏的时候都会执行一下这段代码
-- 目的是清理一下加载的文件，以及重设一下_ENV，确保
-- 两个子游戏之间复用同样一个lua虚拟机而不会干扰彼此
-- 当然任意时刻只能有一个子游戏正在运行着，不能同时运行
-- 两个子游戏。大厅和子游戏则不同，他们是两个不同的lua虚拟机
local launchSubModuleLuaCode = [[
local logger = require 'lobby/lcore/logger'

local function onGameExit()
    logger.trace('onGameExit:', _ENV.thisMod.modName)
    for k,_ in pairs(package.loaded) do
        package.loaded[k] = nil
    end
end

local function onGameEnter()
    logger.trace('onGameEnter:', _ENV.thisMod.modName)
    local env = {}
    local origin = _ENV
    local newenv = setmetatable({}, {
        __index = function (_, k)
            local v = env[k]
            if v == nil then return origin[k] end
            return v
        end,
        __newindex = env,
    })

    _ENV = newenv
    _ENV.thisMod:RegisterCleanup(onGameExit)
end

onGameEnter()
]]

-- 子游戏模块会调用本函数（通过跨lua虚拟机调用）
_ENV.gameServerScheme = function()
	-- 以后这个host也统一到某个lua文件中，由它结合防DDOS流程来给出
	-- "ws://172.18.3.126:3001"
	return "ws://localhost:3001"
end

local function showLoginView()
	local loginView = require "lobby/scripts/login/loginView"
	loginView.showLoginView()
end

local function main()
	local lobbyVer = lenv.VER_STR
	local csharpVer = CS.Version.VER_STR

	--日志等级设置
	logger.level = lenv.loglevel
	CS.BestHTTP.HTTPManager.Logger.Level = lenv.bestHTTP.loglevel

	logger.warn("lobby/Boot begin, lobby version:", lobbyVer, ",csharp version:", csharpVer)
	fairy.GRoot.inst:SetContentScaleFactor(1136, 640)

	_ENV.thisMod:RegisterCleanup(shutdownCleanup)
	_ENV.thisMod.launchSubModuleLuaCode = launchSubModuleLuaCode

	showLoginView()
end

main()
