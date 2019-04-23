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

    private string logPath;

    // 用于每间隔一定时间调用一次lua虚拟机做GC
    private static float lastGCTime = 0;
    private const float GCInterval = 1;//1 second 

    private FairyGUILoader floader;

    // Boot的静态唯一实例
    private static Boot instance;

    // Start is called before the first frame update
    void Start()
    {
        instance = this;

        DoStart();
    }

    private void DoStart()
    {
        System.Diagnostics.Stopwatch stopWatch = new System.Diagnostics.Stopwatch();
        stopWatch.Start();

        // 启动lobby大厅模块
        lobby = new ModuleHub("lobby", null, this);

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

    private void DoDestroy()
    {
        // 销毁UI残余界面，否则可能UI组件引用着LUA中的回调函数
        // 就会导致销毁lua虚拟机时抛异常
        FairyGUI.Timers.inst.Clear();
        FairyGUI.GRoot.inst.Dispose();

        // 最后销毁大厅模块
        if (lobby != null)
        {
            lobby.OnDestroy();
            lobby = null;
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

        instance.DoDestroy();
        instance.DoStart();

        yield return null;
    }

    void OnApplicationQuit()
    {
        Debug.Log("Application ending after " + Time.time + " seconds");
    }
}
