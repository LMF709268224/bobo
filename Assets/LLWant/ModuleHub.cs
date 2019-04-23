using System;
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
    // lua虚拟机
    public readonly XLua.LuaEnv luaenv;
    // 模块名字
    public readonly string modName;
    // 模块资源加载器，例如require 某个lua文件时，由loader去决定从哪里读取这个文件到lua虚拟机中
    public ILoader loader;
    // 父模块，只有游戏模块有父模块，指向lobby模块。而lobby模块的父模块为null
    public readonly ModuleHub parent;

    // 所有子模块，只有lobby模块才具有子模块
    public Dictionary<string, ModuleHub> subModules = new Dictionary<string, ModuleHub>();

    // 所有lua脚本中往c#注册的销毁时回调函数
    private List<VoidLuaFunc> cleanup = new List<VoidLuaFunc>();
    // 所有本模块加载的ui包，模块销毁时会卸载
    private HashSet<string> myUIPackage = new HashSet<string>();

    // delegate定义
    [XLua.CSharpCallLua]
    public delegate void VoidLuaFunc();
    [XLua.CSharpCallLua]
    public delegate string StringLuaFunc(string param);

    // 保存一个MonoBehaviour，用于使用unity的coroutine
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

        // 选择模块的使用的加载器
        SelectModuleLoader();
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
    public void Launch(string jsonString = null)
    {
        // 给lua虚拟机注入一些模块，例如jason模块，protocol buffer模块等等
        LuaEnvInit.AddBasicBuiltin(luaenv);

        // 设置this到lua虚拟机中，脚本可以通过thisMod访问module hub对象
        luaenv.Global.Set("thisMod", this);

        // 模块的启动参数，主要是传递一些参数给lua脚本，参数是一个json字符串
        if (jsonString != null)
        {
            // lua脚本中通过launchArgs访问该json字符串
            luaenv.Global.Set("launchArgs", jsonString);
        }

        // 约定每一个模块都必须有一个main.lua文件，从这个文件开始执行
        var entryLuaFile = $"{modName}/main";
        luaenv.DoString($"require '{entryLuaFile}'", entryLuaFile);
    }

    /// <summary>
    /// 如果lua脚本中注册了销毁时回调函数，调用它
    /// </summary>
    private void CallCleanup()
    {
        foreach(var c in cleanup)
        {
            c.Invoke();
        }

        cleanup.Clear();
        cleanup = null;
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
            // 从父模块删除
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

        GC.Collect(GC.MaxGeneration, GCCollectionMode.Optimized, blocking: true);

        // 执行lua中定义的cleanup函数
        CallCleanup();

        // 重设thisMod为null，取消和lua的关系，否则会luaenv dispose时抛异常: dispose with c# callback
        luaenv.Global.Set("thisMod", (object)null);
        // 销毁lua虚拟机
        luaenv.Dispose();

        // 卸载bundle包
        loader.Unload();

        // 卸载fairyUI加载的UI包
        foreach(var p in myUIPackage)
        {
            FairyGUI.UIPackage.RemovePackage(p);
        }

        Debug.LogWarning($"module {modName} destroyed");
    }

    /// <summary>
    /// 选择一个资源加载器
    ///
    /// 1. 如果可写目录下存在模块目录，则优先使用可写目录作为资源目录
    /// 2. 如果可写目录不存在模块目录，则两种情况：
    /// 2.1 如果处于编辑器模式，则使用assets目录
    /// 2.2 如果不处于编辑器模式，则使用streamingAssets目录
    /// </summary>
    void SelectModuleLoader()
    {

        var writeModuleDir = Path.Combine(Application.persistentDataPath, "modules", modName);
        if (Directory.Exists(writeModuleDir))
        {
            Debug.Log($"{writeModuleDir} exist, try to use writable dir");
            var modePathRoot = Application.persistentDataPath;
#if !UNITY_EDITOR
            if (IsStreamingAssetsPathModVersionNewer())
            {
                // 只读目录模块的cfg.json内的版本号比较新，这可能是由于刚安装了更加新版本的APP，自带的
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
#if UNITY_EDITOR
            Debug.Log($"{writeModuleDir} not exist, use readonly dir editor Assets directory");
            loader = new AssetsFolderLoader(modName);
#else
            Debug.Log($"{writeModuleDir} not exist, use readonly dir streamingAssetsPath directory");
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

            // 把形如 require 'a.b.c'替换成 require 'a/b/c'
            // 注意lua代码中，万万不能require('a.lua')，因为这样的话，路径名是a.lua，
            // 会被下面这行代码替换为：a/lua了，就加载失败
            patch = patch.Replace('.', '/');
            // 确保文件名字带有".lua"后缀，这样才能跟
            // 打包时的文件名对应，注意lua代码中，万万不能require('a.lua')，因为这样的话，路径名是a.lua，
            // 会被上面这行代码替换为：a/lua了，就加载失败
            filepath = patch + ".lua";

            // Debug.Log($"load lua file:{filepath}");
            return loader.LoadTextAsset(filepath);
        });
    }

    /// <summary>
    /// 等待若干毫秒，然后执行回调
    /// </summary>
    /// <param name="milliseconds">多少毫秒</param>
    /// <param name="callback">回调函数</param>
    public void WaitMilliseconds(int milliseconds, VoidLuaFunc callback)
    {
        monoBehaviour.StartCoroutine(MyWaitForSeconds(milliseconds, callback));
    }

    /// <summary>
    /// 使用unity的coroutine来完成异步等待
    /// </summary>
    /// <param name="milliseconds"></param>
    /// <param name="callback"></param>
    /// <returns></returns>
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

    public string CallLobbyStringFunc(string funcName, string param = null)
    {
        if (parent == null)
        {
            throw new Exception($"try to call funcName:{funcName}, but parent module is null");
        }

        var fn = parent.luaenv.Global.Get<StringLuaFunc>(funcName);
        if (fn != null)
        {
            return fn.Invoke(param);
        }

        return null;
    }

    /// <summary>
    /// 新建一个游戏模块
    /// </summary>
    /// <param name="gameModName">游戏模块名字</param>
    public void LaunchGameModule(string gameModName, string jsonString)
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
        if (subModules.Count > 0)
        {
            throw new System.Exception($"LaunchGameModule {gameModName} failed, only support 1 game module on running");
        }

        // 界面必须清空后才能进入子游戏
        var guiChildrenCount = FairyGUI.GRoot.inst._children.Count;
        if (guiChildrenCount > 0)
        {
            throw new System.Exception($"GRoot.inst's children count should be zero, but now it is {guiChildrenCount}");
        }

        // 新建子模块，并添加到子模块列表
        var m = new ModuleHub(gameModName, this, monoBehaviour);
        subModules.Add(gameModName, m);

        // 执行模块目录下的mian.lua文件
        m.Launch(jsonString);
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

    /// <summary>
    /// 等待本帧完成后，再执行DoBackToLobby
    /// </summary>
    /// <returns></returns>
    IEnumerator DoBackToLobbyNextFrame()
    {
        yield return new WaitForEndOfFrame();

        DoBackToLobby();

        yield return null;
    }

    /// <summary>
    /// 销毁本模块，然后回到lobby模块
    /// </summary>
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

    /// <summary>
    /// 调用lua脚本中的backToLobby函数
    /// 注意只有lobby模块才会有这个流程
    /// </summary>
    /// <param name="gameModName"></param>
    private void OnBackToLobby(string gameModName)
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
        path = AppendModPrefix(path, modName);
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

    /// <summary>
    /// 给资源路径增加模块名字，规则是，如果路径已经包含了lobby前缀了，那就不做修改；
    /// 如果路径已经以模块名字开头，也不做修改了；
    /// 否则就把模块名字作为前缀加到路径名上
    /// </summary>
    /// <param name="assetPath">资源的路径名</param>
    /// <param name="moduleName">模块名</param>
    /// <returns></returns>
    internal static string AppendModPrefix(string assetPath, string moduleName)
    {
        if (assetPath.StartsWith("lobby"))
        {
            // 已经是以lobby模块名字问前缀
            return assetPath;
        }

        if (assetPath.StartsWith(moduleName))
        {
            return assetPath;
        }

        return Path.Combine(moduleName, assetPath);
    }
}
