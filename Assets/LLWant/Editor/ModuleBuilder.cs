using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class ModuleBuilder
{
    public readonly ProductCfg.ModuleCfg Cfg;
    private readonly List<BundleBuilder> bundleBuilders = new List<BundleBuilder>();
    private readonly string version;

    public ModuleBuilder(ProductCfg.ModuleCfg cfg, string version, CreateAssetBundlesContext ctx)
    {
        Cfg = cfg;

        foreach(var b in Cfg.Bundles)
        {
            var bb = new BundleBuilder(b, ctx);
            bundleBuilders.Add(bb);
        }

        this.version = version;
    }

    public bool Build(List<AssetBundleBuild> abbList)
    {
        if (bundleBuilders.Count < 1)
        {
            return false;
        }

        foreach(var bb in bundleBuilders)
        {
            var abb = bb.CreateAssetBundleBuild();
            if (abb.assetNames.Length < 1)
            {
                continue;
            }

            abbList.Add(abb);
        }

        if (abbList.Count < 1)
        {
            return false;
        }

        Debug.Log($"abbList count:{abbList.Count}");

        return true;
    }

    public static void BuildProductModules(ProductCfg pcfg, CreateAssetBundlesContext ctx)
    {
        var abbList = new List<AssetBundleBuild>();
        var modbList = new List<ModuleBuilder>();

        // build Lobby
        foreach(var mcfg in pcfg.Modules)
        {
            var vs = GetVersionString(mcfg.Name);
            var mb = new ModuleBuilder(mcfg, vs, ctx);
            if (mb.Build(abbList))
            {
                modbList.Add(mb);
            }
        }

        if (abbList.Count < 1)
        {
            Debug.Log("no bundle found in cfg file, nothing to do");
            return;
        }

        AssetDatabase.Refresh();
        var manifest = BuildPipeline.BuildAssetBundles(ctx.outputRootDir, abbList.ToArray(), ctx.options,ctx.target);
        if (manifest == null)
        {
            return;
        }

        // for each module, copy bundles to its folder, and generate cfg.json
        foreach (var mb in modbList)
        {
            CreateModOutputCfg(mb, ctx, manifest);
        }
    }

    private static void CreateModOutputCfg(ModuleBuilder mb, CreateAssetBundlesContext ctx, UnityEngine.AssetBundleManifest manifest)
    {
        var outputRootDir = ctx.outputRootDir;
        var targetDir = System.IO.Path.Combine(outputRootDir,"out", mb.Cfg.Name);
        System.IO.Directory.CreateDirectory(targetDir);

        // copy bundle files
        foreach(var bb in mb.bundleBuilders)
        {
            var bName = bb.BundleName;
            var srcFileName = System.IO.Path.Combine(outputRootDir, bName);
            var dstFileName = System.IO.Path.Combine(targetDir, bName);

            System.IO.File.Copy(srcFileName, dstFileName);
        }

        // generate cfg json file
        var mcfg = new ModOutputCfg();
        mcfg.name = mb.Cfg.Name;
        mcfg.version = mb.version;
        mcfg.csVer = ctx.csVersion;
        mcfg.lobbyVer = ctx.lobbyVersion;

        var bcfgList = new List<ModBundleOutputCfg>();
        foreach(var bb in mb.bundleBuilders)
        {
            var bName = bb.BundleName;
            var srcFileName = System.IO.Path.Combine(outputRootDir, bName);
            var bcfg = new ModBundleOutputCfg();

            bcfg.name = bName;
            var bytes = System.IO.File.ReadAllBytes(srcFileName);
            bcfg.md5 = NetHelper.MD5(bytes);
            bcfg.size = bytes.Length;

            bcfg.deps = manifest.GetDirectDependencies(bName);
            bcfgList.Add(bcfg);
        }

        mcfg.abList = bcfgList.ToArray();

        var cfgFileName = System.IO.Path.Combine(targetDir, "cfg.json");
        var json = UnityEngine.JsonUtility.ToJson(mcfg, true);

        System.IO.File.WriteAllText(cfgFileName, json);
    }

    private static string GetVersionString(string modName)
    {
        var versionLuaFileName = System.IO.Path.Combine(UnityEngine.Application.dataPath, ProductCfg.MODULES_PATH, modName, "version.lua");
        var text = System.IO.File.ReadAllText(versionLuaFileName);
        var verstrIndex = text.IndexOf("VER_STR");
        var quto1Index = text.IndexOf("\"", verstrIndex+1);
        var quto2Index = text.IndexOf("\"", quto1Index + 1);

        var vstr = text.Substring(quto1Index + 1, quto2Index - quto1Index - 1);
        return vstr;
    }

    public static string GetLobbyVersionString()
    {
        return GetVersionString(ProductCfg.LOBBY_MODULE_NAME);
    }

    public static string GetCSVersionString()
    {
        return Version.VER_STR;
    }
}
