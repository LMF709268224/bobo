using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FairyGUILoader
{
    private ModuleHub lobby;

    public FairyGUILoader(ModuleHub lobby)
    {
        this.lobby = lobby;

        if (lobby.loader is AssetBundleLoader)
        {
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

        // TODO:以后可以注释掉
        Debug.Log($"myFairyUILoadFunc, name:{name}, in-bundle name:{inBundleName}, extension:{extension}, type:{type}");

        // TODO: 如果不属于lobby模块，则找到对应的模块然后请求该模块加载
        return lobby.loader.LoadFromBundleAsType(assetPath, type);
    }
}
