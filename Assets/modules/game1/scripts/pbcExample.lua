CS.UnityEngine.Debug.Log('Main.lua')
require 'Lobby/Lcore/Lcore'

-- local rapidjson = require('rapidjson')
-- local t = rapidjson.decode('{"a":123}')
-- logger.debug(t.a)
-- t.a = 456
-- local s = rapidjson.encode(t)
-- logger.debug('json', s)

-- local protobuf = require "Lobby/Lcore/protobuf"
-- local addr = io.open("D:\\u3d_demo\\bobo\\Assets\\addressbook.pb","rb")
-- buffer = addr:read "*a"
-- addr:close()

-- protobuf.register(buffer)

-- t = protobuf.decode("google.protobuf.FileDescriptorSet", buffer)

-- proto = t.file[1]

-- logger.debug(proto.name)
-- logger.debug(proto.package)

-- message = proto.message_type

-- for _,v in ipairs(message) do
	-- logger.debug(v.name)
	-- for _,v in ipairs(v.field) do
		-- logger.debug("\t".. v.name .. " ["..v.number.."] " .. v.label)
	-- end
-- end

-- local addressbook = {
	-- name = "Alice",
	-- id = 12345,
	-- phone = {
		-- { number = "1301234567" },
		-- { number = "87654321", type = "WORK" },
	-- }
-- }

-- local code = protobuf.encode("tutorial.Person", addressbook)

-- decode = protobuf.decode("tutorial.Person" , code)

-- logger.debug(decode.name)
-- logger.debug(decode.id)
-- for _,v in ipairs(decode.phone) do
	-- logger.debug("\t"..v.number, v.type)
-- end

-- phonebuf = protobuf.pack("tutorial.Person.PhoneNumber number","87654321")
-- buffer = protobuf.pack("tutorial.Person name id phone", "Alice", 123, { phonebuf })
-- logger.debug(protobuf.unpack("tutorial.Person name id phone", buffer))

local lobby = {version = '1.0.0'}
CS.Lobby.LaunchNewGame('GameA', "GameA/Main", "lobbyCfg", lobby)
