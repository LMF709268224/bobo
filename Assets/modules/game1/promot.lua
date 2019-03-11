
--Test Https Get
-- local fn = function(originalRequest, response)
	-- local msg = 'http request completed, url:' .. originalRequest.Uri:ToString() .. ',response code:' .. response.StatusCode
	-- CS.UnityEngine.Debug.Log(msg)
-- end

-- CS.NetHelper.HttpGet('https://baidu.com', fn)

--Test Https Post


--Test WSS
local protobuf = require "Lobby/Lcore/protobuf"
local addr = io.open("D:\\u3d_demo\\bobo\\Assets\\addressbook.pb","rb")
buffer = addr:read "*a"
addr:close()

protobuf.register(buffer)

local addressbook = {
	name = "Alice",
	id = 12345,
	phone = {
		{ number = "1301234567" },
		{ number = "87654321", type = "WORK" },
	}
}

local encoded = protobuf.encode("tutorial.Person", addressbook)

CS.UnityEngine.Debug.Log('encoded length:' .. #encoded)

local ws = CS.NetHelper.NewWebSocket('ws://demos.kaazing.com/echo')
local wsClean = function(w)
	w.OnOpen = nil
	w.OnClosed = nil
	w.OnError = nil
	w.OnMessage = nil
	w.OnPong = nil
	w.OnBinary = nil
	w.PingDataProvider = nil
end

ws.OnOpen = function(ws)
	CS.UnityEngine.Debug.Log('ws opened')
	ws.StartPingThread = true

	ws:SendText('hello')
	-- local binay = {}
	-- for i=1, 10 do
      -- binay[i] = 0
    -- end

	ws:SendBinary(encoded)
	--ws:Close(1003, 'world')
end

ws.OnClosed = function(ws, code, msg)
	CS.UnityEngine.Debug.Log('ws closed, code:' .. code .. ',msg:' .. msg)
end

ws.OnError = function(ws)
	CS.UnityEngine.Debug.Log('ws error')
	wsClean(ws)
end

ws.OnMessage = function(ws, text)
	CS.UnityEngine.Debug.Log('ws text msg:' .. text)
end

ws.OnPong = function(ws, pongData)
	local ms = CS.NetHelper.TimeElapsedMilliseconds(pongData)
	CS.UnityEngine.Debug.Log('ws pong data, ms:' .. ms)
end

ws.OnBinary = function(ws, binary)
	CS.UnityEngine.Debug.Log('ws binary msg, length:' .. #binary)
	
	local decode = protobuf.decode("tutorial.Person" , binary)

	CS.UnityEngine.Debug.Log(decode.name)
	CS.UnityEngine.Debug.Log(decode.id)
	for _,v in ipairs(decode.phone) do
		CS.UnityEngine.Debug.Log("\t"..v.number..','..v.type)
	end	
end

ws.PingDataProvider = function()
	return CS.NetHelper.CurrentUTCTime2Bytes()
end

ws:Open()
