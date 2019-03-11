using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;

public class BundleBuilder
{
    public readonly ProductCfg.BundleCfg Cfg;
    public readonly string modulePath;
    public readonly string BundleName;
    private CreateAssetBundlesContext ctx;

    public BundleBuilder(ProductCfg.BundleCfg cfg, CreateAssetBundlesContext ctx)
    {
        Cfg = cfg;
        var path = cfg.Path;
        path = path.Replace('\\', '/');
        path = path.Replace('/', '_');
        BundleName = path.ToLower();
        this.ctx = ctx;

        modulePath = Path.Combine(ctx.modulesRootPath, Cfg.Path);
    }

    public AssetBundleBuild CreateAssetBundleBuild()
    {
        string[] files;
        if (Cfg.IsText)
        {
            // copy to temporary folder, and rename to ".txt" files
            files = Copy2TextTemporaryFolder();
        }
        else
        {
            files = GetFiles(modulePath);
        }

        var assetNames = new List<string>();
        var addressableNames = new List<string>();
        foreach (var p in files)
        {
            string npath = p.Substring(p.IndexOf("Assets"));
            var assetName = npath.Replace('\\', '/');
            var addressableName = assetName;
            if (Cfg.IsText)
            {
                // 重新生成一个没有临时目录，以及去掉.txt的寻址名字
                addressableName = addressableName.Replace($"/{ProductCfg.TEXT_PATH_TEMP}","");
                addressableName = addressableName.Replace(".bytes", "");
            }

            Debug.Log($"file name:{assetName}");
            assetNames.Add(assetName);
            addressableNames.Add(addressableName);
        }

        AssetBundleBuild build = new AssetBundleBuild();
        build.assetBundleName = this.BundleName;
        build.assetNames = assetNames.ToArray();
        build.addressableNames = addressableNames.ToArray();

        Debug.Log($"New bunndle build, name:{Cfg.Path}");
        return build;
    }

    private string[] GetFiles(string modulePath)
    {
        return Directory
            .GetFiles(modulePath, "*.*")
            .Where(file => Cfg.Filter.Contains(Path.GetExtension(file)))
            .ToArray();
    }

    private string[] Copy2TextTemporaryFolder()
    {
        var files = GetFiles(modulePath);
        var targetPath = Path.Combine(ctx.textTEMPPath, Cfg.Path);

        if (Directory.Exists(targetPath))
        {
            Directory.Delete(targetPath, true);
        }

        Directory.CreateDirectory(targetPath);

        var copyFiles = new List<string>();

        foreach(var f in files)
        {
            var fileName = Path.GetFileName(f);
            var newF = Path.Combine(targetPath, fileName+".bytes");

            File.Copy(f, newF, true);

            copyFiles.Add(newF);
        }

        return copyFiles.ToArray();
    }
}
