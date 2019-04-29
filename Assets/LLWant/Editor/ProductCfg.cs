using System.IO;
using System.Runtime.Serialization;
using System.Collections.Generic;
using System.Runtime.Serialization.Json;
using System.Text;
using System;

[DataContract]
public class ProductCfg
{
    public const string TEXT_PATH_TEMP = "TextABTemp";
    public const string MODULES_PATH = "modules";
    public static string LOBBY_MODULE_NAME = "lobby";

    [DataContract]
    public class BundleCfg
    {
        [DataMember(Name = "path")]
        public string Path;

        [DataMember(Name = "filters")]
        public string Filter;

        [DataMember(Name = "istxt")]
        public bool IsText = false;

        public void Dump(StringBuilder sb)
        {
            sb.AppendLine($"bundle path:{Path}, filters:{Filter}");
        }
    }

    [DataContract]
    public class ModuleCfg
    {
        [DataMember(Name = "name")]
        public string Name;

        [DataMember(Name = "bundles")]
        public List<BundleCfg> Bundles = new List<BundleCfg>();

        public void Dump(StringBuilder sb)
        {
            sb.AppendLine($"ModuleCfg name:{Name}");

            if (Bundles != null && Bundles.Count > 0)
            {
                sb.AppendLine("ModuleCfg Bundles:");
                foreach(var b in Bundles)
                {
                    b.Dump(sb);
                }
            }
        }
    }

    [DataMember(Name = "name")]
    public string Name;

    [DataMember(Name = "modules")]
    public List<ModuleCfg> Modules = new List<ModuleCfg>();

    public void Dump(StringBuilder sb)
    {
        sb.AppendLine($"Product name:{Name}");

        foreach(var m in Modules)
        {
            m.Dump(sb);
        }
    }

    public static ProductCfg LoadFromFile(string path)
    {
        DataContractJsonSerializer ser = new DataContractJsonSerializer(typeof(ProductCfg));
        var text = File.ReadAllBytes(path);
        using(MemoryStream stream = new MemoryStream(text))
        {
            ProductCfg obj = (ProductCfg)ser.ReadObject(stream);
            obj.Verify();

            return obj;
        }
    }

    private void Verify()
    {
        var mNMap = new Dictionary<string, bool>();
        var bNMap = new Dictionary<string, bool>();

        foreach(var m in Modules)
        {
            if (mNMap.ContainsKey(m.Name))
            {
                throw new Exception($"module name {m.Name} duplicate");
            }

            mNMap.Add(m.Name, true);

            foreach(var b in m.Bundles)
            {
                if (bNMap.ContainsKey(b.Path))
                {
                    throw new Exception($"bundle path {b.Path} duplicate");
                }

                bNMap.Add(b.Path, true);
            }
        }
    }
}
