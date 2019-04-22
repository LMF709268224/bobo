using System.Collections;
using System.Collections.Generic;
using UnityEngine;
/// <summary>
/// 用于替换fairygui中的加载UIPackage的过程
/// 因为我们的资源可能位于我们自己打包规则生成的bundle中，所以
/// 需要自定义一个加载过程，从我们的bundle中加载UIPackage
/// </summary>
public class FairyGUILoader
{
    private ModuleHub lobby;

    public FairyGUILoader(ModuleHub lobby)
    {
        this.lobby = lobby;

        if (lobby.loader is AssetBundleLoader)
        {
            // 当且仅当目前的加载器类型是bundle加载器时，才需要替换fairygui的加载过程
            FairyGUI.UIPackage.customiseLoadFunc = myFairyUILoadFunc;
        }
    }

    private object myFairyUILoadFunc(string name, string extension, System.Type type, out FairyGUI.DestroyMethod destroyMethod)
    {
        var inBundleName = name;
        if (name.StartsWith(AssetBundleLoader.pathPrefix))
        {
            inBundleName = name.Substring(AssetBundleLoader.pathPrefix.Length);
        }

        destroyMethod = FairyGUI.DestroyMethod.Unload;
        var assetPath = inBundleName + extension;

        // 以后可以注释掉
        // Debug.Log($"myFairyUILoadFunc, name:{name}, in-bundle name:{inBundleName}, extension:{extension}, type:{type}");

        if (inBundleName.StartsWith("lobby"))
        {
            return lobby.loader.LoadFromBundleAsType(assetPath, type);
        }

        // 如果不属于lobby模块，则找到对应的模块然后请求该模块加载
        foreach(var m in lobby.subModules.Values)
        {
            if (inBundleName.StartsWith(m.modName))
            {
                return m.loader.LoadFromBundleAsType(assetPath, type);
            }
        }

        return null;
    }
}
