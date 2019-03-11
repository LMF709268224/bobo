using System.Collections.Generic;
using System.Runtime.Serialization;

/// <summary>
/// BundleOutputCfg和打包流程输出的json文件相对应
/// 表示一个bundle的json格式
/// 
/// 只是提取json文件中其中一部分有用的内容，目前只是提取依赖关系
/// </summary>
[DataContract]
public class BundleOutputCfg
{
    [DataMember(Name = "name")]
    public string name;

    [DataMember(Name = "deps")]
    public string[] deps;
}

/// <summary>
/// ModuleOutputCfg和打包流程输出的json文件相对应
/// 表示一个模块的json格式
/// 
/// 只是提取json文件中其中一部分有用的内容
/// </summary>
[DataContract]
public class ModuleOutputCfg
{
    [DataMember(Name = "abList")]
    public List<BundleOutputCfg> abList = new List<BundleOutputCfg>();
}

/// <summary>
/// 只提取version字符串
/// </summary>
[DataContract]
public class ModuleOutputVersionCfg
{
    [DataMember(Name = "version")]
    public string Version;
}
