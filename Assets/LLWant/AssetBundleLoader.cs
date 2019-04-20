using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization.Json;
using UnityEngine;

/// <summary>
/// 从bundle中读取资源，bundle可能位于persistentDataPath
/// 也可能位于streamingAssetsPath目录
/// </summary>
public class AssetBundleLoader : ILoader
{
    private readonly string path;
    private readonly string moduleName;
    private readonly AssetBundleLoader parent;
    public const string pathPrefix = "Assets/modules/";

    private Dictionary<string, AssetBundle> bundleMap = new Dictionary<string, AssetBundle>();
    private Dictionary<string, string[]> bundleDepsMap = null;

    public AssetBundleLoader(string moduleName, AssetBundleLoader parent, string modulePath)
    {
        Debug.Log($"New AssetBundleLoader, moduleName:{moduleName}, modulePath:{modulePath}");
        this.moduleName = moduleName.ToLower();
        this.parent = parent;
        this.path = modulePath + "/" + moduleName;
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
        assetPath = ModuleHub.AppendModPrefix(assetPath, moduleName);
        var ta = LoadFromBundle<TextAsset>(assetPath);
        if (ta == null)
        {
            Debug.LogError($"load {assetPath} failed");
            return null;
        }

        return ta.bytes;
    }

    [XLua.LuaCallCSharp]
    [XLua.ReflectionUse]
    public GameObject LoadGameObject(string assetPath)
    {
        assetPath = ModuleHub.AppendModPrefix(assetPath, moduleName);
        var go = LoadFromBundle<GameObject>(assetPath);
        return go;
    }

    [XLua.LuaCallCSharp]
    [XLua.ReflectionUse]
    public Texture2D LoadTexture2D(string assetPath)
    {
        assetPath = ModuleHub.AppendModPrefix(assetPath, moduleName);
        var go = LoadFromBundle<Texture2D>(assetPath);
        return go;
    }

    public UnityEngine.Object LoadFromBundleAsType(string assetPath, System.Type type)
    {
        assetPath = ModuleHub.AppendModPrefix(assetPath, moduleName);
        // 首先根据路径转为包名，这是打包的时候约定的：所有分隔符替换为下划线来组成bundle名
        var bundleName = Path2AssetBundleName(assetPath);
        var bundle = GetBundle(bundleName);

        if (bundle == null)
        {
            Debug.LogError($"load {assetPath} failed, bundle {bundleName} not found");
            return null;
        }

        // 打包的时候，通过addressableNames把bundle中的资源的访问名字改为
        // Assets/Lobby/Main.lua这样的风格，而不是 Assets/Tmp/Lobby/Main.lua.bytes
        var assetPathInBundle = pathPrefix + assetPath;
        var ta = bundle.LoadAsset(assetPathInBundle, type);

        return ta;
    }

    private T LoadFromBundle<T>  (string assetPath) where T:UnityEngine.Object
    {
        var ta = (T)LoadFromBundleAsType(assetPath, typeof(T));
        if (ta == null)
        {
            Debug.LogError($"load asset from {assetPath} failed");
        }

        return ta;
    }

    /// <summary>
    /// 获取bundle，如果bundle不属于本loader的，则请求父亲节点
    /// 判断bundle是否属于本loader，是简单的对bundle名字对比，bundle名字是由本loader的module name开头的
    /// 就认为是本loader的
    /// </summary>
    /// <param name="bundleName"></param>
    /// <returns></returns>
    private AssetBundle GetBundle(string bundleName)
    {
        // 判断是否本loader管理的bundle
        if (!IsMyBundle(bundleName))
        {
            if (parent != null)
            {
                return parent.GetBundle(bundleName);
            }

            Debug.LogError($"{bundleName} not {moduleName}'s bundle, load bundle failed");
            return null;
        }

        if (bundleMap.ContainsKey(bundleName))
        {
            return bundleMap[bundleName];
        }
        else
        {
            // try to load bundle
            return LoadBundleFromFile(bundleName);
        }
    }

    /// <summary>
    /// 卸载所有被本loader加载进来的bundles
    /// </summary>
    public void Unload()
    {
        foreach(var entry in bundleMap)
        {
            var b = entry.Value;
            // 用true表示卸载所有加载了的对象，如果此时视图中尚有此类对象
            // 就会显示紫红色，丢失了
            b.Unload(true);
        }

        bundleMap.Clear();
    }

    /// <summary>
    /// 尝试加载一个bundle，调用之前需要确保bundleMap不存在相同名字的bundle
    /// </summary>
    /// <param name="bundleName">bundle名</param>
    /// <returns></returns>
    private AssetBundle LoadBundleFromFile(string bundleName)
    {
        var filePath = $"{path}/{bundleName}";
        var b = AssetBundle.LoadFromMemory(NetHelper.UnityWebRequestLocalGet(filePath));
        if (b == null)
        {
            Debug.LogError($"LoadBundleFromFile failed, bundle name: {bundleName}, filePath:{filePath} not found or is not bundle format");
            return null;
        }

        // 先记录到bundleMap
        bundleMap.Add(bundleName, b);

        // 加载bundle的所有依赖bundle
        LoadAllDeps(bundleName);

        return b;
    }

    /// <summary>
    /// 判断bundle是否属于本loader管理，也即是bundle的名字是否以本loader的module name开头
    /// 例如，module name是lobby的，bundle name必须是 "lobby"或者"lobby_xxxx"这样的才属于
    /// 本loader管理的
    /// </summary>
    /// <param name="bundleName"></param>
    /// <returns></returns>
    private bool IsMyBundle(string bundleName)
    {
        return bundleName.StartsWith(moduleName);
    }

    /// <summary>
    /// 根据bundle名字，找到bundle的所有的依赖，并把依赖加载进来
    /// </summary>
    /// <param name="bundleName"></param>
    private void LoadAllDeps(string bundleName)
    {
        if (bundleDepsMap == null)
        {
            LoadBundleDepsMap();
        }

        if (bundleDepsMap == null)
        {
            return;
        }

        if (!bundleDepsMap.ContainsKey(bundleName))
        {
            // no deps found
            return;
        }

        var deps = bundleDepsMap[bundleName];
        foreach(var d in deps)
        {
            Debug.Log($"try to get dep {d} for bundle {bundleName}");
            var dp = GetBundle(d);
            if (dp == null)
            {
                Debug.LogError($"failed to get dep bundle:{d} for {bundleName}");
            }
        }
    }

    /// <summary>
    /// 读取模块目录下的cfg.json（这个文件是打包流程生成的，里面有每个bundle依赖别的bundle的信息）
    /// </summary>
    private void LoadBundleDepsMap()
    {
        var cfgJSONFileName = $"{path}/cfg.json";
        DataContractJsonSerializer ser = new DataContractJsonSerializer(typeof(ModuleOutputCfg));
        var text = NetHelper.UnityWebRequestLocalGet(cfgJSONFileName);
        using (MemoryStream stream = new MemoryStream(text))
        {
            ModuleOutputCfg obj = (ModuleOutputCfg)ser.ReadObject(stream);

            bundleDepsMap = new Dictionary<string, string[]>();
            foreach(var bo in obj.abList)
            {
                if (bo.deps == null || bo.deps.Length < 1)
                {
                    continue;
                }

                // 把bundle名字和bundle依赖的其他bundle名字关联起来，便于后面查找bundle的依赖关系
                bundleDepsMap.Add(bo.name, bo.deps);
            }
        }
    }

    /// <summary>
    /// 把路径转换为bundle名字，根据定好的打包规则：形如 "lobby/lcore"形式的路径，对应的bundle名字是lobby_lcore
    /// 也就是把"/"替换为"_"，把路径分隔符替换成下划线
    /// </summary>
    /// <param name="assetPath"></param>
    /// <returns></returns>
    private string Path2AssetBundleName(string assetPath)
    {
        var dirName = Path.GetDirectoryName(assetPath);

        // windows下路径风格符'\\'
        dirName = dirName.Replace('\\', '_');
        // 把路径分割符替换成下划线
        dirName = dirName.Replace('/', '_');
        // 转成小写（unity生成bundle时默认是小写）
        dirName = dirName.ToLower();

        return dirName;
    }
}
