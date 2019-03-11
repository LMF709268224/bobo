--[[
Description:
	Login.lua 登录逻辑
	
Note:
	函数名，变量名以camel case风格命名。
	不允许全局变量。
	
	类名可以大写开头。
--]]

local logger = require 'lobby/logger'
local loader = _ENV._loader

local function login()
	logger.trace('lobby/login login()')
	local go = loader:LoadGameObject('lobby/prefabsB/myb.prefab')
	print(go)
end

return login
