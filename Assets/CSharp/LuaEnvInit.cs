using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LuaEnvInit
{
    public static void AddBasicBuiltin(XLua.LuaEnv luaenv)
    {
        luaenv.AddBuildin("rapidjson", XLua.LuaDLL.Lua.LoadRapidJson);
        luaenv.AddBuildin("protobuf.c", XLua.LuaDLL.Lua.LoadProtobufC);
    }
}
