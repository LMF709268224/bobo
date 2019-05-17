using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using UnityEditor;

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

        CheckTextCfg();
    }

    /// <summary>
    /// 如果文件类型包含".lua"文件，则检查是否配置为text
    /// </summary>
    private void CheckTextCfg()
    {
        var hasLua = Cfg.Filter.Contains(".lua");
        var isText = Cfg.IsText;
        if (hasLua != isText)
        {
            throw new Exception($"bundle cfg:{Cfg.Path} lua and text type mismatch,"+
                " should config as text if has lua file, otherwise not");
        }
    }

    public AssetBundleBuild CreateAssetBundleBuild()
    {
        string[] files;
        if (Cfg.IsText)
        {
            // copy to temporary folder, and rename to ".bytes" files
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
                // 重新生成一个没有临时目录，以及去掉.bytes的寻址名字
                addressableName = addressableName.Replace($"/{ProductCfg.TEXT_PATH_TEMP}","");
                addressableName = addressableName.Replace(".bytes", "");
            }

            UnityEngine.Debug.Log($"file name:{assetName}");
            assetNames.Add(assetName);
            addressableNames.Add(addressableName);
        }

        AssetBundleBuild build = new AssetBundleBuild();
        build.assetBundleName = this.BundleName;
        build.assetNames = assetNames.ToArray();
        build.addressableNames = addressableNames.ToArray();

        UnityEngine.Debug.Log($"New bunndle build, name:{Cfg.Path}");
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

            // 如果是lua文件，则调用lua compiler，程序名字是luac53.exe，把lua文本
            // 转换为去掉注释的字节码，以节省空间和提审加载速度
            // 因此环境变量Path路径中必须可以找到luac程序
            if (fileName.EndsWith(".lua"))
            {
                CompileLuaFile(f, newF);
            }
            else
            {
                // 不是lua文本，则直接copy到目标临时目录
                File.Copy(f, newF, true);
            }

            copyFiles.Add(newF);
        }

        return copyFiles.ToArray();
    }

    /// <summary>
    /// 把lua脚本使用luac编译成字节码，以便提高加载速度和节省一点空间
    /// 当前使用的是luac53.exe，64位版本，下载地址：
    /// http://luabinaries.sourceforge.net/download.html
    /// </summary>
    /// <param name="fileName"></param>
    /// <param name="newF"></param>
    private void CompileLuaFile(string fileName, string newF)
    {
        UnityEngine.Debug.Log($"compile lua file:{fileName}");
        var command = $"-o \"{newF}\" \"{fileName}\"";

        var pProcess = new System.Diagnostics.Process();
        pProcess.StartInfo.FileName = "luac53.exe";
        pProcess.StartInfo.Arguments = command; //argument
        pProcess.StartInfo.UseShellExecute = false;
        pProcess.StartInfo.RedirectStandardOutput = true;
        pProcess.StartInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
        pProcess.StartInfo.CreateNoWindow = true; //not diplay a windows
        pProcess.Start();

        string output = pProcess.StandardOutput.ReadToEnd(); //The output result
        pProcess.WaitForExit();

        if (pProcess.ExitCode != 0)
        {
            throw new Exception($"luac53.exe compile {fileName} failed:{output}");
        }
    }
}
