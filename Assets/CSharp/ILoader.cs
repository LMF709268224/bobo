using UnityEngine;

/// <summary>
/// 提取个公共接口，用于适配2种环境下读取资源
/// 第1种环境是editor模式下从assets目录读取资源；
/// 第2种环境是从streamassets目录，或者可写persisten data path
/// 读取资源，这种情况下资源都位于bundle中
/// </summary>
public interface ILoader
{
    GameObject LoadGameObject(string assetPath);

    byte[] LoadTextAsset(string assetPath);

    Texture2D LoadTexture2D(string assetPath);

    UnityEngine.Object LoadFromBundleAsType(string assetPath, System.Type type);

    void Unload();
}
