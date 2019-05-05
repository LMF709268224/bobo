using System;
using System.IO;
using UnityEngine;

/// <summary>
/// Unity对咱们逻辑代码的第一入口
/// 
/// 把Boot.cs挂在canvas或者某个全局game object下
/// </summary>
public class Boot : MonoBehaviour
{
    // 大厅模块，之后的其他游戏模块，由大厅模块激活
    private ModuleHub lobby;

    private StreamWriter logWriter;

    // 用于每间隔一定时间调用一次lua虚拟机做GC
    private static float lastGCTime = 0;
    private const float GCInterval = 1;//1 second 

    private FairyGUILoader floader;

    // Boot的静态唯一实例
    internal static Boot instance;
    // 游戏模块专用的lua虚拟机
    internal XLua.LuaEnv gameLuaEnv;
    // 大厅专用的lua虚拟机
    internal XLua.LuaEnv lobbyLuaEnv;

    // Start is called before the first frame update
    void Start()
    {
        instance = this;

        SubscribeLog();

        DoStart();
    }

    void SubscribeLog()
    {
        if (Application.platform != RuntimePlatform.Android
            && Application.platform != RuntimePlatform.IPhonePlayer)
        {
            // 只在这两个平台上，才启用自定义的日志记录
            return;
        }

        var logFileName = "Player.log";
        var preLogFileName = "Player-prev.log";
        var logFilePath = Path.Combine(Application.persistentDataPath, logFileName);
        var preLogFilePath = Path.Combine(Application.persistentDataPath, preLogFileName);

        if (File.Exists(preLogFilePath))
        {
            File.Delete(preLogFilePath);
        }

        if (File.Exists(logFilePath))
        {
            File.Move(logFilePath, preLogFilePath);
        }

        logWriter = new StreamWriter(logFilePath, false, System.Text.Encoding.UTF8);
        Application.logMessageReceived += (logString, stackTrace, type) =>
        {
            // 只写，不flush
            logWriter.Write("[" + type + "]" + logString + "\r\n");
        };
    }

    private void DoStart()
    {
        System.Diagnostics.Stopwatch stopWatch = new System.Diagnostics.Stopwatch();
        stopWatch.Start();

        lobbyLuaEnv = new XLua.LuaEnv();
        gameLuaEnv = new XLua.LuaEnv();
        LuaEnvInit.AddBasicBuiltin(lobbyLuaEnv);
        LuaEnvInit.AddBasicBuiltin(gameLuaEnv);

        // 启动lobby大厅模块
        lobby = new ModuleHub("lobby", null, this, lobbyLuaEnv);

        floader = new FairyGUILoader(lobby);

        lobby.Launch();

        stopWatch.Stop();
        Debug.Log($"Boot.Start total time:{stopWatch.Elapsed.TotalMilliseconds} milliseconds");
    }

    // Update is called once per frame
    void Update()
    {
        if (lobby != null)
        {
            if (Time.time - lastGCTime > GCInterval)
            {
                lobby.Tick();
                lastGCTime = Time.time;
            }
        }
    }

    void OnDestroy()
    {
        Debug.Log("Boot.OnDestroy");
        DoDestroy();
    }

    private void DoDestroy(bool disposeGRoot = true)
    {
        // 销毁UI残余界面，否则可能UI组件引用着LUA中的回调函数
        // 就会导致销毁lua虚拟机时抛异常
        FairyGUI.Timers.inst.Clear();
        FairyGUI.GRoot.inst.CleanupChildren();

        if (disposeGRoot)
        {
            FairyGUI.GRoot.inst.Dispose();
        }

        // 最后销毁大厅模块
        if (lobby != null)
        {
            lobby.OnDestroy();
            lobby = null;
        }

        if (gameLuaEnv != null)
        {
            gameLuaEnv.Dispose();
        }

        if (lobbyLuaEnv != null)
        {
            lobbyLuaEnv.Dispose();
        }
    }

    /// <summary>
    /// LUA脚本调用本函数重新加载大厅
    /// </summary>
    public static void Reboot()
    {
        if (instance != null)
        {
            Debug.Log("Boot.Reboot");

            instance.StartCoroutine(DoReboot());
        }
        else
        {
            Debug.LogError("Boot.Reboot failed, instance is null");
        }
    }

    static System.Collections.IEnumerator DoReboot()
    {
        yield return new WaitForEndOfFrame();

        instance.DoDestroy(false);
        instance.DoStart();

        yield return null;
    }

    void OnApplicationQuit()
    {
        Debug.Log("Application ending after " + Time.time + " seconds");

        // 如果日志文件存在，则关闭文件
        if (logWriter != null)
        {
            logWriter.Flush();
            logWriter.Close();
        }
    }
}
