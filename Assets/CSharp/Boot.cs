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
    private static ModuleHub lobby;

    private string logPath;
    private StreamWriter logger;

    // 用于每间隔一定时间调用一次lua虚拟机做GC
    private static float lastGCTime = 0;
    private const float GCInterval = 1;//1 second 

    private FairyGUILoader floader;

    // Start is called before the first frame update
    void Start()
    {
        System.Diagnostics.Stopwatch stopWatch = new System.Diagnostics.Stopwatch();
        stopWatch.Start();

        // 先订阅一下日志，把日志写到文件
        SubscribeLogMsg();

        // 启动lobby大厅模块
        lobby = new ModuleHub("lobby", null, this);

        floader = new FairyGUILoader(lobby);

        lobby.Launch();

        stopWatch.Stop();
        Debug.Log($"Boot.Start total time:{stopWatch.Elapsed.TotalMilliseconds} milliseconds");
    }

    /// <summary>
    /// 订阅unity的日志，输出到文件
    /// 
    /// 两个日志文件，loga和logb，轮流使用
    /// </summary>
    private void SubscribeLogMsg()
    {
        var logPathA = Path.Combine(Application.persistentDataPath, "loga.txt");
        var logPathB = Path.Combine(Application.persistentDataPath, "logb.txt");

        if (!File.Exists(logPathA))
        {
            logPath = logPathA;
        }
        else if (!File.Exists(logPathB))
        {
            logPath = logPathB;
        }
        else
        {
            // 比较两个文件的最后修改时间，选择较早那个
            DateTime modificationA = File.GetLastWriteTime(logPathA);
            DateTime modificationB = File.GetLastWriteTime(logPathB);

            if (modificationA.CompareTo(modificationB) >= 0)
            {
                logPath = logPathB;
            }
            else
            {
                logPath = logPathA;
            }
        }

        if (File.Exists(logPath))
        {
            // 先删除旧的
            File.Delete(logPath);
        }

        try
        {
            logger = new StreamWriter(logPath, false, System.Text.Encoding.UTF8);
            Application.logMessageReceived += WriteLog2File;
        }
        catch(System.Exception ex)
        {
            Debug.LogException(ex);
        }
    }

    private string LogTypeString(LogType t)
    {
        switch (t)
        {
            case LogType.Assert:
                return "Assert";
            case LogType.Error:
                return "Error";
            case LogType.Exception:
                return "Exception";
            case LogType.Log:
                return "Log";
            case LogType.Warning:
                return "Warn";
            default:
                return "Unknown";
        }
    }

    private void WriteLog2File(string condition, string stackTrace, LogType type)
    {
        if (logger != null)
        {
            var dateStr = DateTime.Now.ToString("MM/dd/yyyy HH:mm:ss");
            var logMsg = new string[] { $"[{dateStr}][{LogTypeString(type)}]{condition}" };
            logger.WriteLine(logMsg);
        }
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
        FairyGUI.GRoot.inst.Dispose();
        lobby.OnDestroy();
        lobby = null;
    }

    void OnApplicationQuit()
    {
        Debug.Log("Application ending after " + Time.time + " seconds");
    }
}
