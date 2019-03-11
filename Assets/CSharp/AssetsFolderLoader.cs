using System.IO;
using UnityEngine;
#if UNITY_EDITOR

/// <summary>
/// 从assets目录读取资源
/// </summary>
public class AssetsFolderLoader: ILoader
{
    private readonly string moduleName;

    public AssetsFolderLoader(string moduleName)
    {
        this.moduleName = moduleName.ToLower();
    }
 
    /// <summary>
    /// 加载TextAsset类型的资源，资源名字不能带前缀"Assets/"，因为本函数会附加这个前缀
    /// </summary>
    /// <param name="assetPath">资源名字</param>
    /// <returns></returns>
    [XLua.LuaCallCSharp]
    [XLua.ReflectionUse]
    public byte[] LoadTextAsset(string assetPath)
    {
        var assetPathInBundle = Path.Combine(UnityEngine.Application.dataPath, "modules", assetPath);
        return NetHelper.UnityWebRequestLocalGet(assetPathInBundle);
    }

    [XLua.LuaCallCSharp]
    [XLua.ReflectionUse]
    public GameObject LoadGameObject(string assetPath)
    {
        var go = LoadFromAssetsFolder<GameObject>(assetPath);
        return go;
    }

    private T LoadFromAssetsFolder<T>(string assetPath) where T : UnityEngine.Object
    {
        T ta = null;
        // 打包的时候，通过addressableNames把bundle中的资源的访问名字改为
        // Assets/Lobby/Main.lua这样的风格，而不是 Assets/Tmp/Lobby/Main.lua.txt
        var assetPathInBundle = "Assets/modules/" + assetPath;
        ta = (T)UnityEditor.AssetDatabase.LoadAssetAtPath(assetPathInBundle, typeof(T));
        if (ta == null)
        {
            Debug.LogError($"load asset from {assetPathInBundle} failed");
        }

        return ta;
    }

    [XLua.LuaCallCSharp]
    [XLua.ReflectionUse]
    public Texture2D LoadTexture2D(string assetPath)
    {
        var go = LoadFromAssetsFolder<Texture2D>(assetPath);
        return go;
    }

    public UnityEngine.Object LoadFromBundleAsType(string assetPath, System.Type type)
    {
        throw new System.NotImplementedException();
    }

    public void Unload()
    {

    }
}
#endif
