--[[
Description:
	Logger.lua 日志输出，主要增加一个等级控制
	
Note:
	函数名，变量名以camel case风格命名。
	不允许全局变量。
	
	类名可以大写开头。
--]]

local Logger = {}

Logger.traceLv = 1
Logger.debugLv = 2
Logger.infoLv = 3
Logger.warnLv = 4
Logger.errorLv = 5
Logger.fatalLv = 6

Logger.level = Logger.traceLv

--根据不同的日志等级映射到Unity中的日志函数
local logMap = {
	[Logger.traceLv] = function (msg)
		CS.UnityEngine.Debug.Log(msg)
	end,
	[Logger.debugLv] = function (msg)
		CS.UnityEngine.Debug.Log(msg)
	end,
	[Logger.infoLv] = function (msg)
		CS.UnityEngine.Debug.Log(msg)
	end,
	[Logger.warnLv] = function (msg)
		CS.UnityEngine.Debug.LogWarning(msg)
	end,
	[Logger.errorLv] = function (msg)
		CS.UnityEngine.Debug.LogError(msg)
	end,
	[Logger.fatalLv] = function (msg)
		CS.UnityEngine.Debug.LogError(msg)
	end
}

-- COPY from http://lua-users.org/wiki/TableSerialization
local function table_print (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    local sb = {}
    for key, value in pairs (tt) do
      table.insert(sb, string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        table.insert(sb, key .. " = {\n");
        table.insert(sb, table_print (value, indent + 2, done))
        table.insert(sb, string.rep (" ", indent)) -- indent it
        table.insert(sb, "}\n");
      elseif "number" == type(key) then
        table.insert(sb, string.format("\"%s\"\n", tostring(value)))
      else
        table.insert(sb, string.format(
            "%s = \"%s\"\n", tostring (key), tostring(value)))
       end
    end
    return table.concat(sb)
  else
    return tt .. "\n"
  end
end

-- COPY from http://lua-users.org/wiki/TableSerialization
local function to_string( tbl )
    if  "nil"       == type( tbl ) then
        return tostring(nil)
    elseif  "table" == type( tbl ) then
        return table_print(tbl)
    elseif  "string" == type( tbl ) then
        return tbl
    else
        return tostring(tbl)
    end
end

function Logger.log(level, args)
	if (Logger.level > level) then
		--忽略日志
		return
	end
	
	--最幼稚地处理：串接所有参数，也即是假定所有参数都是string
	local msg = ''
	for _, a in ipairs(args) do
		msg = msg .. to_string(a)
	end

	logMap[level](msg)
end

function Logger.trace(...)
	local args = { ... }
	Logger.log(Logger.traceLv, args)
end

function Logger.debug(...)
	local args = { ... }
	Logger.log(Logger.debugLv, args)
end

function Logger.info(...)
	local args = { ... }
	Logger.log(Logger.infoLv, args)
end

function Logger.warn(...)
	local args = { ... }
	Logger.log(Logger.warnLv, args)
end

function Logger.error(...)
	local args = { ... }
	Logger.log(Logger.errorLv, args)
end

function Logger.fatal(...)
	local args = { ... }
	Logger.log(Logger.fatalLv, args)
end

return Logger
