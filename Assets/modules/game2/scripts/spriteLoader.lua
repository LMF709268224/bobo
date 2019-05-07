
--麻将底图/花色资源加载器

local Loader = {}

--图片资源缓存
local cache = { }
setmetatable(cache, {__mode = "k"})
local dfPath = "GuanZhang/Script/"
local dfCompatibleAPI = require(dfPath ..'dfMahjong/dfCompatibleAPI')

function Loader.LoadSprite(path, name)
    return dfCompatibleAPI:loadDynPic(path..name)
    -- local key = path..name
    -- if not cache[key] then
    --     cache[key] = resMgr:LoadImgSprite(name, path)
    -- end
    -- return cache[key]
end

return Loader

