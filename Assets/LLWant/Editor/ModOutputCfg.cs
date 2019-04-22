using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[Serializable]
public class ModOutputCfg
{
    public string name;
    public string version;
    public ModBundleOutputCfg[] abList;
}

[Serializable]
public class ModBundleOutputCfg
{
    public string name;
    public string md5;
    public int size;
    public string[] deps;
}
