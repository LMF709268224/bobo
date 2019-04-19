--[[
Description:
	animations.lua 动画播放管理器

Note:
	函数名，变量名以camel case风格命名。
	不允许全局变量。

	类名可以大写开头。
--]]

local logger = require "lobby/lcore/logger"
local fairy = require "lobby/lcore/fairygui"

local AnimationMgr = {}

local prefabsCached = {}
local gameObjectsCached = {}

local function createGameObject(prefabName)
	local prefab = prefabsCached[prefabName]
	if prefabCached == nil then
		prefab = _ENV.thisMod.loader:LoadGameObject(prefabName)
		prefabsCached[prefabName] = prefab
	end

	-- 实例化
	local go = CS.UnityEngine.Object.Instantiate(prefab);
	-- 给动画节点加一个canvas，以便它里面的canvas renderer能够绘图
	CS.UIHelper.AddCanvas(go, 1136, 640)

	-- 找到界面上的锚点，并把动画节点挂载上去
	local holder = fairy.GGraph()
	local wrapper = CS.FairyGUI.GoWrapper(go)
	holder:SetNativeObject(wrapper)

	local animator = go:GetComponent(typeof(CS.UnityEngine.Animator))
	local particles = CS.UIHelper.GetAllParticle(go)
	return {holder = holder, go = go, wrapper = wrapper, animator = animator, particles = particles}
end

local function playGameObject(goCached, parentComponent)
	-- 重新激活
	goCached.wrapper.visible = true
	goCached.go:SetActive(false)
	goCached.go:SetActive(true)

	-- 启动定时器，去检测动画是否完成
	parentComponent:StopTimer(goCached.prefabName)
	parentComponent:StartTimer(goCached.prefabName, 0.5, 0, function ()
		local animator = goCached.animator
		local stateInfo = animator:GetCurrentAnimatorStateInfo(0);
		--logger.debug('playGameObject timer callback:', stateInfo.normalizedTime)
		if stateInfo.normalizedTime < 1 then
			return
		end

		-- 检查是否所有的粒子都完成
		if not CS.UIHelper.IsParticleFinished(goCached.particles) then
			return
		end

		-- 动画已经结束
		parentComponent:StopTimer(goCached.prefabName)
		goCached.wrapper.visible = false
		goCached.go:SetActive(false)
	end)
end

function AnimationMgr.play(prefabName, parentComponent, x, y)
	logger.debug('AnimationMgr.play prefabName:', prefabName)

	-- 检查是否有可用的game object，如果有则直接使用
	local goCached = gameObjectsCached[prefabName]
	if goCached == nil then
		logger.debug('AnimationMgr.play, goCached nil, create new game Object')
		goCached = createGameObject(prefabName)
		gameObjectsCached[prefabName] = goCached

		parentComponent:AddChild(goCached.holder)

		goCached.prefabName = prefabName
	end

	-- reposistion
	goCached.holder.x = x
	goCached.holder.y = y

	playGameObject(goCached, parentComponent)
end

return AnimationMgr
