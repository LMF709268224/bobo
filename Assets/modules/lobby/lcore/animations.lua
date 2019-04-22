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
local CS = _ENV.CS
local typeof = _ENV.typeof

local function createGameObject(prefabName)
	local prefab = prefabsCached[prefabName]
	if prefab == nil then
		prefab = _ENV.thisMod.loader:LoadGameObject(prefabName)
		prefabsCached[prefabName] = prefab
	end

	-- 实例化
	local go = CS.UnityEngine.Object.Instantiate(prefab)
	-- 给动画节点加一个canvas，以便它里面的canvas renderer能够绘图
	CS.UIHelper.AddCanvas(go, 1136, 640)

	-- 动画节点挂载到GGraph上
	local holder = fairy.GGraph()
	local wrapper = CS.FairyGUI.GoWrapper(go)
	wrapper:SetSize(0, 0)
	holder:SetNativeObject(wrapper)

	local animator = go:GetComponent(typeof(CS.UnityEngine.Animator))
	local particles = CS.UIHelper.GetAllParticle(go)
	return {holder = holder, go = go, wrapper = wrapper, animator = animator, particles = particles}
end

local function playGameObject(goCached, ctx)
	-- 重新激活
	local noAutoHide = ctx.noAutoHide
	local coYield = ctx.coYield
	local parentComponent = goCached.parentComponent
	goCached.wrapper.visible = true
	goCached.go:SetActive(false)
	goCached.go:SetActive(true)

	if noAutoHide then
		return
	end

	local particleLoopKilled = 0
	local co = nil
	-- 启动定时器，去检测动画是否完成
	parentComponent:StopTimer(goCached.prefabName)
	parentComponent:StartTimer(
		goCached.prefabName,
		0.5,
		0,
		function()
			local animator = goCached.animator
			local stateInfo = animator:GetCurrentAnimatorStateInfo(0)
			--logger.debug('playGameObject timer callback:', stateInfo.normalizedTime)
			if stateInfo.normalizedTime < 1 then
				return
			end

			particleLoopKilled = particleLoopKilled + 1

			-- 检查是否所有的粒子都完成，如果5秒都还没有完成，就不再等待，直接结束
			if not CS.UIHelper.IsParticleFinished(goCached.particles) and particleLoopKilled < 10 then
				return
			end

			-- 动画已经结束
			parentComponent:StopTimer(goCached.prefabName)
			goCached.wrapper.visible = false
			goCached.go:SetActive(false)

			-- 如果需要唤醒coroutine
			if coYield then
				local r, err = coroutine.resume(co)
				if not r then
					logger.error(debug.traceback(co, err))
				end
			end
		end
	)

	if coYield then
		co = coroutine.running()
		coroutine.yield()
	end
end

local function getGocached(ctx)
	local prefabName = ctx.prefabName
	local parentComponent = ctx.parentComponent
	local x = ctx.x
	local y = ctx.y

	-- 检查是否有可用的game object，如果有则直接使用
	local goCached = gameObjectsCached[prefabName]
	if goCached == nil then
		logger.debug("AnimationMgr.getGocached, goCached nil, create new game Object for:", prefabName)

		goCached = createGameObject(prefabName)
		gameObjectsCached[prefabName] = goCached

		parentComponent:AddChild(goCached.holder)

		goCached.parentComponent = parentComponent
		goCached.prefabName = prefabName
	end

	if goCached.parentComponent ~= parentComponent then
		-- 把定时器停止，然后从老的父节点移除
		goCached.parentComponent:StopTimer(prefabName)
		goCached.holder:RemoveFromParent()

		--加入到新的父节点
		parentComponent:AddChild(goCached.holder)
		goCached.parentComponent = parentComponent
	end

	-- reposistion
	goCached.holder.x = x
	goCached.holder.y = y

	return goCached
end

function AnimationMgr.playAnimation(ctx)
	logger.debug("AnimationMgr.playAnimation prefabName:", ctx.prefabName)

	local goCached = getGocached(ctx)
	playGameObject(goCached, ctx)
end

function AnimationMgr.play(prefabName, parentComponent, x, y, noAutoHide)
	local ctx = {
		prefabName = prefabName,
		parentComponent = parentComponent,
		x = x,
		y = y,
		noAutoHide = noAutoHide
	}

	AnimationMgr.playAnimation(ctx)
end

function AnimationMgr.coplay(prefabName, parentComponent, x, y)
	local ctx = {
		prefabName = prefabName,
		parentComponent = parentComponent,
		x = x,
		y = y,
		coYield = true
	}

	AnimationMgr.playAnimation(ctx)
end

return AnimationMgr
