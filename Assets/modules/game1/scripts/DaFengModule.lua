local DaFengModule = {}

DaFengModule.moduleName = "DaFengModule"
--HallModule.cfg = {luaPath = "HallComponent.Script.HallView", resPath = "Component/HallComponent/Bundle/prefab/HallView.prefab"};
----------------------------------------------

local dispatcher = g_ModuleMgr:GetModule(ModuleName.DISPATCH_MODULE)

local memoryCheck = g_ModuleMgr:GetModule(ModuleName.MEMORYCHECK_MODULE)
local memoryCount = 0

function DaFengModule:Init()
    if memoryCheck then
        --游戏模块lua内存占用分析（内存占用）
        collectgarbage("collect")
        self.memoryCount = collectgarbage("count")
        --游戏模块lua内存占用分析（快照）
        collectgarbage("collect")
        memoryCheck:DumpAllMemorySnapshot("DaFengModule-1")

        --游戏模块lua内存占用分析（内存占用）
        local memoryDifference = collectgarbage("count")- self.memoryCount
        logRed("[memory] DaFengModule init finised。add memory: " .. memoryDifference .. "k")
    end
    dispatcher:register("START_DAFENG", self, self.StartDaFeng)
end

function DaFengModule:UnInit()
    dispatcher:unregister("START_DAFENG", self, self.StartDaFeng)
    self:CleanModule()
    if memoryCheck then
    	--游戏模块lua内存占用分析（内存占用）
        collectgarbage("collect")
    	local memoryDifference = collectgarbage("count")- self.memoryCount
    	logRed("[memory] DaFengModule UnInit finised。add memory leak: " .. memoryDifference .. "k")
        --游戏模块lua内存占用分析（快照）
        collectgarbage("collect")
        memoryCheck:DumpAllMemorySnapshot("DaFengModule-2")
        --游戏模块lua内存占用分析（内存泄漏）
        collectgarbage("collect")
        memoryCheck:DumpAllMemorySnapshotComparedFile("DaFengModule", "DaFengModule-1", "DaFengModule-2")
    end
end

function DaFengModule:StartDaFeng(url, myUser, roomInfo)
    local DF = require("GuanZhang/Script/dfMahjong/dfSingleton")
    if DF then
        local dfSingleton = DF:getSingleton()
        local co =
            coroutine.create(
            function()
                dfSingleton:tryEnterRoom(url, myUser, roomInfo)
            end
        )
        coroutine.resume(co)
    end
end

function DaFengModule:CleanModule()
    local DF = require("GuanZhang/Script/dfMahjong/dfSingleton")
    if DF then
        --退出dfSingleton WebSocket
        local dfSingleton = DF:getSingleton()
        dfSingleton:forceExit2LoginView()
    end
end

return DaFengModule
