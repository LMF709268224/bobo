using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LuaEnvInit
{
    /// <summary>
    /// 给lua虚拟机增加一些内建的组件，这样lua脚本才可以require这些组件
    /// </summary>
    /// <param name="luaenv"></param>
    public static void AddBasicBuiltin(XLua.LuaEnv luaenv)
    {
        luaenv.AddBuildin("rapidjson", XLua.LuaDLL.Lua.LoadRapidJson);
        luaenv.AddBuildin("protobuf.c", XLua.LuaDLL.Lua.LoadProtobufC);
    }
}
