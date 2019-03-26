local logger = require 'lobby/lcore/logger'
local fairy = require 'lobby/lcore/fairygui'

logger.warn('i am game1')

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

local function onSkipClick(context)
	print('you click on '..context.sender.name)
end

local gooo = nil

-- 由C#调用
local function shutdownCleanup()
	if mylobbyView ~= nil then
		mylobbyView:Dispose()
	end

	logger.warn('game1 cleanup')
	print_func_ref_by_csharp()
end

local function onSettingClick(context)
	local popup = fairy.UIPackage.CreateObject('runfast_setting', 'setting')
	--弹出在自定义的位置
	fairy.GRoot.inst:ShowPopup(popup)

	local win = fairy.Window()
	win.contentPane = popup
	win.modal = true
	--win:SetXY(1136/2, 0)

	local yesBtn = popup:GetChild('n1')
	yesBtn.onClick:Add(function(context)
		win:Hide()
		win:Dispose()
	end)

	local noBtn = popup:GetChild('n2')
	noBtn.onClick:Add(function(context)
		fairy.GRoot.inst:CleanupChildren()
		_ENV.thisMod:BackToLobby()
	end)

	win:Show()
end

local function onTipsClick(context)
	print('you click on '..context.sender.name)
end

local function onDiscardClick(context)
	print('you click on '..context.sender.name)
	gooo.visible = false
end

local function onRoomInfoClick(context)
	print('you click on '..context.sender.name)
	gooo.visible = true
end

local YY = 0
local function fillCards(myView)
	local pokers = {'desk_poker_number_lo', 'desk_poker_jqk_lo', 'desk_poker_joker_lo'}
	for i = 1,16 do
		local cname = 'n'..i
		local go = myView:GetChild(cname)
		if go ~= nil then
			local card = fairy.UIPackage.CreateObject('runfast', pokers[(i-1)%3 +1])
			card.position = go.position
			
			if i == 1 then
				local flag = card:GetChild('n2')
				flag.url = 'ui://p966ud2tef8pw'
			end

			myView:AddChild(card)
			YY = card.y
			local btn = card:GetChild('n0')
			btn.onClick:Add(function(context)
				if card.y >= YY then
					card.y = card.y - 20
				else
					card.y = card.y + 20
				end
			end)
		else
			logger.error('can not found child:', cname)
		end
	end
end

local function testGame1UI()
	_ENV.thisMod:RegisterCleanup(shutdownCleanup)

	_ENV.thisMod:AddUIPackage('lobby/fui_lobby_poker/lobby_poker')
	_ENV.thisMod:AddUIPackage('game1/bg/runfast_bg_2d')
	_ENV.thisMod:AddUIPackage('game1/fgui/runfast')
	_ENV.thisMod:AddUIPackage('game1/setting/runfast_setting')
	local view = fairy.UIPackage.CreateObject('runfast', 'desk')
	fairy.GRoot.inst:AddChild(view)
	local operationPanel = view:GetChild('n31')
	local skipBtn = operationPanel:GetChild('n1')
	skipBtn.enabled = false
	skipBtn.onClick:Add(onSkipClick)
	
	local tipsBtn = operationPanel:GetChild('n0')
	tipsBtn.onClick:Add(onTipsClick)
	
	local discardBtn = operationPanel:GetChild('n2')
	discardBtn.onClick:Add(onDiscardClick)
	
	local topRoomInfoBtn = view:GetChild('n35')
	topRoomInfoBtn.onClick:Add(onRoomInfoClick)
	
	local settingBtn = view:GetChild('n7')
	settingBtn.onClick:Add(onSettingClick)
	
	local myView = view:GetChild('n29')
	fillCards(myView:GetChild('plist'))
	
	gooo = operationPanel
end

testGame1UI()
