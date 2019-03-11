local logger = require 'lobby/lcore/logger'
local lenv = require 'lobby/lenv'
--local errHelper = require 'lobby/LobbyErrHelper'
local fairy = require 'lobby/lcore/fairygui'

logger.warn('lobby main startup')

-- 打印所有被C#引用着的LUA函数
local function print_func_ref_by_csharp()
    local registry = debug.getregistry()
    for k, v in pairs(registry) do
        if type(k) == 'number' and type(v) == 'function' and registry[v] == k then
            local info = debug.getinfo(v)
            print(string.format('%s:%d', info.short_src, info.linedefined))
        end
    end
end

-- 由C#调用
local function shutdownCleanup()
	logger.warn('lobby main cleanup')
	print_func_ref_by_csharp()
end

local function doUpgrade()
	-- 准备检查更新Lobby模块
	local updaterM = require 'lobby/lcore/updater'
	local updater = updaterM:new('lobby', lenv.URL.updateQuery)
	
	local err = nil
	local isNeedUpgrade = false

	err, isNeedUpgrade = updater:checkUpdate()

	-- 检查阶段就已经发生错误
	if err ~= nil then
		return err
	end

	-- 如果有更新，执行更新
	if isNeedUpgrade then
		err = updater:doUpgrade(function(event, downloaded, total) end)
	end

	-- 返回err
	return err, isNeedUpgrade
end

local function isUpgradeEnable()
	-- 除非配置为强制启用更新（用于测试更新逻辑）
	if lenv.forceUseUpgrade then
		return true
	end

	-- 如果处于编辑器模式，则不启用更新
	local isEditor = CS.UnityEngine.Application.isEditor
	return not isEditor
end

local function msgBox(err)
	return false
end

local function mainEntryCoroutine()
	logger.trace('mainEntryCoroutine()')

	-- 先显示启动背景
	local err = nil
	local upgraded = false

	-- 如果使用更新
	if isUpgradeEnable() then
		local retry = true
		-- 失败时，不断重试
		while retry do
			-- 尝试检查和实施更新
			err, upgraded = doUpgrade()
			if err ~= nil then 
				-- 发生错误，询问是否重试
				retry = msgBox(err)
			else
				break
			end
		end
	end

	if err ~= nil then
		-- 发生错误，退出
		logger.error('Error:', err.msg, 'Code:', err.code, ',程序将结束运行')
		--_ENV._mhub:AppExit()
		return
	end

	if upgraded then
		-- 更新完成后，卸载背景，并reboot
		_ENV._mhub:Reboot()
		return
	end

	-- 开始登录
	-- local login = require ('lobby/Login')
	-- login()
	
	
	--_ENV._mhub:LaunchGameModule("game1")
end

local gooo = nil
local function onStupidClick(context)
  	print('you click on '..context.sender.name)
	
	-- CS.UnityEngine.Object.Destroy(gooo)
	-- gooo = nil
end

local function main()
	local lobbyVer = lenv.VER_STR
	local csharpVer = CS.Version.VER_STR

	--日志等级设置
	logger.level = lenv.loglevel
	CS.BestHTTP.HTTPManager.Logger.Level = lenv.loglevel

	logger.warn('lobby/Boot begin, lobby version:', lobbyVer, ',csharp version:', csharpVer)

	_ENV._mhub:RegisterCleanup(shutdownCleanup)

	-- 启动cortouine
	-- local co = coroutine.create(mainEntryCoroutine)
	-- local r, err = coroutine.resume(co)
	-- if not r then
		-- logger.error(debug.traceback(co, err))
	-- end
	_ENV._mhub:AddUIPackage('lobby/fui/lobbyCommon')
	_ENV._mhub:AddUIPackage('lobby/fui/lobbyMain')
	local view = fairy.UIPackage.CreateObject('lobbyMain', 'MainComp')
	fairy.GRoot.inst:AddChild(view)
	local children = view:GetChildren()
	local length = children.Length
	print('view child count:'..length)
	for i = 0,(length-1) do
		local child = children[i]
		print('child:'..child.name)
	end
	
	local btn = view:GetChild('n5')
	btn.onClick:Add(onStupidClick)
end

main()
