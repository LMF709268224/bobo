using UnityEditor;
using System.IO;
using UnityEngine;

public class CreateAssetBundlesContext
{
    public string textTEMPPath;
    public string outputRootDir;
    public string modulesRootPath;
    public BuildAssetBundleOptions options;
    public BuildTarget target;
    public string csVersion;
    public string lobbyVersion;
}

public class CreateAssetBundles
{
    [MenuItem("Assets/Build AssetBundles")]
    static void BuildAllAssetBundles()
    {
        //BuildPipeline.BuildAssetBundles(assetBundleDirectory, BuildAssetBundleOptions.None, EditorUserBuildSettings.activeBuildTarget);

        var productCfg = ProductCfg.LoadFromFile(System.IO.Path.Combine(UnityEngine.Application.dataPath, "product.json"));

        var options = BuildAssetBundleOptions.DisableWriteTypeTree
            | BuildAssetBundleOptions.ChunkBasedCompression | BuildAssetBundleOptions.DeterministicAssetBundle;

        var outputRootDir = System.IO.Path.Combine(UnityEngine.Application.dataPath, "../AssetBundles");
        var textTempPath = System.IO.Path.Combine(UnityEngine.Application.dataPath, ProductCfg.MODULES_PATH, ProductCfg.TEXT_PATH_TEMP);

        var ctx = new CreateAssetBundlesContext();
        ctx.outputRootDir = outputRootDir;
        ctx.textTEMPPath = textTempPath;
        ctx.options = options;
        ctx.target = EditorUserBuildSettings.activeBuildTarget;
        ctx.modulesRootPath = Path.Combine(UnityEngine.Application.dataPath, ProductCfg.MODULES_PATH);
        ctx.csVersion = ModuleBuilder.GetCSVersionString();
        ctx.lobbyVersion = ModuleBuilder.GetLobbyVersionString();

        if (Directory.Exists(outputRootDir))
        {
            Directory.Delete(outputRootDir, true);
        }

        Cleanup(ctx);

        Directory.CreateDirectory(outputRootDir);

        ModuleBuilder.BuildProductModules(productCfg, ctx);

        Cleanup(ctx);

        AssetDatabase.Refresh();

        Debug.Log("Build AssetBundles Done!");
    }

    private static void Cleanup(CreateAssetBundlesContext ctx)
    {
        
        if (Directory.Exists(ctx.textTEMPPath))
        {
            Directory.Delete(ctx.textTEMPPath, true);
        }
    }
}
