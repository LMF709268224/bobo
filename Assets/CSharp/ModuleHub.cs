using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.Serialization.Json;
using UnityEngine;

/// <summary>
/// 对应一个模块
/// 
/// 例如大厅lobby模块，某某个游戏模块
/// 主要是包含lua虚拟机，以及资源loader，以及界面节点等等
/// 
/// 模块还可以启动子模块，例如大厅模块启动游戏模块
/// 这个时候，子模块和大厅模块有联系，子模块加载资源时如果发现不属于它的资源
/// 就会向大厅模块请求该资源。例如大厅模块含有一套通用的美术资源，所有子游戏
/// 可以使用，子游戏使用该美术资源时，就需要请求大厅模块加载该资源。
/// 
/// Unity启动后，首先是激活Boot.cs，后者则new一个ModuleHub，对应lobby大厅模块
/// 之后进入大厅的环境和逻辑
/// </summary>
[XLua.LuaCallCSharp]
public class ModuleHub
{
    public readonly XLua.LuaEnv luaenv;
    public readonly string modName;
    public ILoader loader;
    public readonly ModuleHub parent;

    public Dictionary<string, ModuleHub> subModules = new Dictionary<string, ModuleHub>();
    private List<VoidLuaFunc> cleanup = new List<VoidLuaFunc>();
    private HashSet<string> myUIPackage = new HashSet<string>();

    [XLua.CSharpCallLua]
    public delegate void VoidLuaFunc();

    private MonoBehaviour monoBehaviour;
    /// <summary>
    /// 构造一个新的ModuleHub，对应一个模块
    /// </summary>
    /// <param name="modName">模块的名字</param>
    /// <param name="parent">父模块，例如游戏模块的父模块是大厅模块</param>
    /// <param name="mountNode">视图节点，模块所有的view都挂在这个节点上</param>
    public ModuleHub(string modName, ModuleHub parent, MonoBehaviour monoBehaviour)
    {
        this.modName = modName;
        this.parent = parent;
        luaenv = new XLua.LuaEnv();
        this.monoBehaviour = monoBehaviour;
    }

    /// <summary>
    /// 只要是为lua虚拟机提供tick，做垃圾回收
    /// </summary>
    public void Tick()
    {
        luaenv.Tick();

        foreach(var s in subModules.Values)
        {
            s.Tick();
        }
    }

    /// <summary>
    /// 执行main.lua
    /// </summary>
    public void Launch()
    {
        LuaEnvInit.AddBasicBuildin(luaenv);
        SelectModulePath();

        luaenv.Global.Set("thisMod", this);

        var entryLuaFile = $"{modName}/main";
        luaenv.DoString($"require '{entryLuaFile}'", entryLuaFile);
    }

    /// <summary>
    /// 如果main.lua中定义了ShutdownCleanup函数，调用它
    /// </summary>
    private void CallCleanup()
    {
        foreach(var c in cleanup)
        {
            c.Invoke();
        }

        cleanup.Clear();
    }

    /// <summary>
    /// 模块销毁
    /// </summary>
    public void OnDestroy()
    {
        DoDestroy();
    }

    private void DoDestroy()
    {
        Debug.Log("ModuleHub.DoDestroy");
        if (parent != null)
        {
            parent.subModules.Remove(modName);
        }

        // 销毁所有的子模块
        // 复制一份values出来，避免一边遍历一边被删除
        foreach (var s in subModules.Values.ToArray())
        {
            s.OnDestroy();
        }

        if (subModules.Count > 0)
        {
            // 竟然还有子模块没有销毁，那么逻辑上肯定是出错了
            Debug.LogError($"{modName} destroyed, but leak {subModules.Count} sub module");
        }

        // 执行lua中定义的cleanup函数
        CallCleanup();

        //Object.Destroy(mountNode.gameObject);

        // 重设_mhub为null，取消和lua的关系，否则会luaenv dispose时抛异常: dispose with c# callback
        luaenv.Global.Set("thisMod", (object)null);
        luaenv.Dispose();

        // 卸载bundle包
        loader.Unload();

        foreach(var p in myUIPackage)
        {
            FairyGUI.UIPackage.RemovePackage(p);
        }

        Debug.LogWarning($"module {modName} destroyed");
    }

    /// <summary>
    /// 选择一个资源加载路径
    /// 
    /// 1. 如果可写目录下存在模块目录，则优先使用可写目录作为资源目录
    /// 2. 如果可写目录不存在模块目录，则两种情况：
    /// 2.1 如果处于编辑器模式，则使用assets目录
    /// 2.2 如果不处于编辑器模式，则使用streamingAssets目录
    /// </summary>
    void SelectModulePath()
    {

        var writeModuleDir = Path.Combine(Application.persistentDataPath, "modules", modName);
        if (Directory.Exists(writeModuleDir))
        {
            Debug.Log($"{writeModuleDir} exist, try to use writable dir");
            var modePathRoot = Application.persistentDataPath;
#if !UNITY_EDITOR
            if (IsStreamingAssetsPathModVersionNewer())
            {
                // 只读目录模块的cfg.json内的版本号比较新，这可能是由于刚安装了更新的APP，自带的
                // 模块版本号比较新的缘故，因此使用只读目录，并删除老的可写目录（清理垃圾）
                Debug.Log("StreamingAssetsPath module version is newer, use StreamingAssetsPath instead of persistentDataPath");
                modePathRoot = Application.streamingAssetsPath;

                Debug.Log("Delete older persistentDataPath module content");
                // 删除老的可写目录模块内容
                Directory.Delete(writeModuleDir, true);
            }
#endif
            modePathRoot = Path.Combine(modePathRoot, "modules");
            AssetBundleLoader parentLoader = parent?.loader as AssetBundleLoader;
            loader = new AssetBundleLoader(modName, parentLoader, modePathRoot);
        }
        else
        {
            Debug.Log($"{writeModuleDir} not exist, use readonly dir");
#if UNITY_EDITOR
            loader = new AssetsFolderLoader(modName);
#else
            AssetBundleLoader parentLoader = parent?.loader as AssetBundleLoader;
            // 用的是StreamingAssetsPath，而不用Resources目录，原因参考下面的链接：
            // https://unity3d.com/learn/tutorials/topics/best-practices/resources-folder
            var modePathRoot = Path.Combine(Application.streamingAssetsPath, "modules");
            loader = new AssetBundleLoader(modName, parentLoader, modePathRoot); 
#endif
        }

        // 把加载器增加到lua虚拟机中
        luaenv.AddLoader((ref string filepath) =>
        {
            var patch = filepath;

            // 确保路径必须以模块名字开头，或者以lobby开头(表示require lobby的lua文件)
            if (parent == null)
            {
                // 本模块是lobby模块
                if (!patch.StartsWith(modName))
                {
                    patch = Path.Combine(modName, patch);
                }
            }
            else
            {
                // 本模块是游戏模块
                if (!patch.StartsWith(modName) && !patch.StartsWith("lobby"))
                {
                    patch = Path.Combine(modName, patch);
                }
            }

            // 把形如 require 'a.b.c'替换成 require 'a/b/c'
            patch = patch.Replace('.', '/');
            // 确保文件名字带有".lua"后缀，这样才能跟
            // 打包时的文件名对应
            filepath = patch + ".lua";
            return loader.LoadTextAsset(filepath);
        });
    }

    public void WaitMilliseconds(int milliseconds, VoidLuaFunc callback)
    {
        monoBehaviour.StartCoroutine(MyWaitForSeconds(milliseconds, callback));
    }

    System.Collections.IEnumerator MyWaitForSeconds(int milliseconds, VoidLuaFunc callback)
    {
        yield return new WaitForSeconds((milliseconds)/1000.0f);
        callback();
    }

    /// <summary>
    /// 退出整个程序
    /// </summary>
    public void AppExit()
    {
        Debug.LogWarning("ModuleHub.AppExit() called, will quit the game");
        // save any game data here
#if UNITY_EDITOR
        // Application.Quit() does not work in the editor so
        // UnityEditor.EditorApplication.isPlaying need to be set to false to end the game
        UnityEditor.EditorApplication.isPlaying = false;
#else
        Application.Quit();
#endif
    }

    /// <summary>
    /// 新建一个游戏模块
    /// </summary>
    /// <param name="gameModName">游戏模块名字</param>
    public void LaunchGameModule(string gameModName)
    {
        // 只有大厅模块的parent才不为null，其他所有游戏模块的parent必须是null
        if (parent != null)
        {
            // 如果parent不等于null，表示模块是游戏模块，游戏模块不能创建新的游戏模块
            throw new System.Exception($"LaunchGameModule {gameModName} failed, module {modName} not lobby");
        }

        // 检查是否新建重复的游戏模块
        if (subModules.ContainsKey(gameModName))
        {
            throw new System.Exception($"LaunchGameModule {gameModName} failed, duplicate module");
        }

        // 检查是否启动多于一个游戏模块，目前仅允许一个游戏在运行
        if (subModules.Count > 1)
        {
            throw new System.Exception($"LaunchGameModule {gameModName} failed, only support 1 game module on running");
        }

        // 界面必须清空后才能进入子游戏
        var guiChildrenCount = FairyGUI.GRoot.inst._children.Count;
        if (guiChildrenCount > 0)
        {
            throw new System.Exception($"GRoot.inst's children count should be zero, but now it is {guiChildrenCount}");
        }

        var m = new ModuleHub(gameModName, this, monoBehaviour);
        subModules.Add(gameModName, m);

        // 执行模块目录下的mian.lua文件
        m.Launch();
    }

    /// <summary>
    /// 游戏子模块调用本函数回到大厅，同时会销毁游戏模块
    /// </summary>
    public void BackToLobby()
    {
        // 只有大厅模块的parent才不为null，其他所有游戏模块的parent必须是null
        if (parent == null)
        {
            // 如果parent不等于null，表示模块是游戏模块，游戏模块不能创建新的游戏模块
            throw new System.Exception($"BackToLobby  failed, module {modName} is already lobby");
        }

        // 用coroutine的方式执行DoBackToLobby，这样才不会导致残留一些c#引用lua代码
        // 避免luaenv dispose时产生异常
        monoBehaviour.StartCoroutine(DoBackToLobbyNextFrame());
    }

    IEnumerator DoBackToLobbyNextFrame()
    {
        yield return new WaitForEndOfFrame();

        DoBackToLobby();

        yield return null;
    }

    private void DoBackToLobby()
    {

        // 界面必须清空后才能进入子游戏
        var guiChildrenCount = FairyGUI.GRoot.inst._children.Count;
        if (guiChildrenCount > 0)
        {
            throw new System.Exception($"GRoot.inst's children count should be zero, but now it is {guiChildrenCount}");
        }

        var lobby = parent;

        DoDestroy();

        lobby.OnBackToLobby(modName);
    }

    public void OnBackToLobby(string gameModName)
    {
        luaenv.Global.Get<VoidLuaFunc>("backToLobby")?.Invoke();
    }

    /// <summary>
    /// Lua 代码通过本函数注册模块销毁时的回调
    /// </summary>
    /// <param name="f"></param>
    public void RegisterCleanup(VoidLuaFunc f)
    {
        cleanup.Add(f);
    }

    /// <summary>
    /// 增加FairyUI的资源包，LUA应该仅调用本函数来增加资源包，因为模块卸载时，可以卸载对应的资源包
    /// </summary>
    /// <param name="path"></param>
    public void AddUIPackage(string path)
    {
        var p = FairyGUI.UIPackage.AddPackage(path);
        if (p != null && !myUIPackage.Contains(p.name))
        {
            Debug.Log($"ModuleHub.AddUIPackage, path:{path}, package name:{p.name}");
            myUIPackage.Add(p.name);
        }
    }

    /// <summary>
    /// 读取并比较streamingAssetsPath和persistentDataPath目录下module的cfg.json文件，并比较版本号
    /// </summary>
    /// <returns></returns>
    private bool IsStreamingAssetsPathModVersionNewer()
    {
        var streamingModPath = Path.Combine(Application.streamingAssetsPath, modName, "cfg.json");
        var persistentModPath = Path.Combine(Application.persistentDataPath, modName, "cfg.json");

        var streamingModCfgJSONBytes = NetHelper.UnityWebRequestLocalGet(streamingModPath);
        if (streamingModCfgJSONBytes == null || streamingModCfgJSONBytes.Length < 1)
        {
            // streaming 目录cfg.json读取不成功
            return false;
        }

        var persistentModCfgJSONBytes = NetHelper.UnityWebRequestLocalGet(persistentModPath);
        if (persistentModCfgJSONBytes == null || persistentModCfgJSONBytes.Length < 1)
        {
            // persistent 目录cfg.json读取不成功
            return true;
        }

        // JSON 读取version字符串
        using (MemoryStream stream = new MemoryStream(streamingModCfgJSONBytes))
        {
            DataContractJsonSerializer ser = new DataContractJsonSerializer(typeof(ModuleOutputVersionCfg));
            ModuleOutputVersionCfg streamingVersion = (ModuleOutputVersionCfg)ser.ReadObject(stream);

            using (MemoryStream stream2 = new MemoryStream(persistentModCfgJSONBytes))
            {
                ModuleOutputVersionCfg persistentVersion = (ModuleOutputVersionCfg)ser.ReadObject(stream2);

                var icmp =  NetHelper.VersionCompare(streamingVersion.Version, persistentVersion.Version);

                Debug.Log($"streamingVersion:{streamingVersion.Version}, persistentVersion:{persistentVersion.Version}, result:{icmp}");
                return icmp > 0;
            }
        }
    }
}
