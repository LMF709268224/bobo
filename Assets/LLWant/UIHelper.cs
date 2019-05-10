using System.Collections.Generic;
using UnityEngine;

public class UIHelper
{
    /// <summary>
    /// 给节点增加一个canvas组件，目前主要是因为我们用的是fairyGUI做UI，而
    /// 美术老的动画资源，是用canvas renderer来做绘图的，因此需要给动画prefab加一个canvas组件。
    /// 这里的canvas只需要设置好size，其他的参数，FairyGUI的GoWrapper.cs类会进行设置的
    /// </summary>
    /// <param name="go">prefab实例化后的game object</param>
    /// <param name="width">canvas 的宽度</param>
    /// <param name="height">canvas 的高度</param>
    public static void AddCanvas(GameObject go, int width, int height)
    {
        if (go.GetComponent<Canvas>() != null)
        {
            return;
        }

        var canvas = go.AddComponent<Canvas>();
        RectTransform rt = canvas.GetComponent<RectTransform>();
        rt.sizeDelta = new Vector2(width, height);
    }

    /// <summary>
    /// 检查是否所有的粒子都完成了
    /// </summary>
    /// <returns></returns>
    public static bool IsParticleFinished(List<ParticleSystem> particels)
    {
        return particels.TrueForAll(e => e != null && e.isStopped);
    }

    /// <summary>
    /// LUA脚本使用本函数把动画prefab的粒子都cache起来，以便后面检查粒子是否完成了
    /// </summary>
    /// <param name="go"></param>
    /// <returns></returns>
    public static List<ParticleSystem> GetAllParticle(GameObject go)
    {
        var particels = new List<ParticleSystem>();
        go.GetComponentsInChildren(true, particels);

        return particels;
    }

    public static UnityEngine.Object GetComponent(UnityEngine.GameObject go, System.Type t)
    {
        var comp = go.GetComponent(t);
        if (comp == null )
        {
            return null;
        }

        return comp;
    }
}
