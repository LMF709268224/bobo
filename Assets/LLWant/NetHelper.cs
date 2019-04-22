using System.Text;
using UnityEngine;
using UnityEngine.Networking;

/// <summary>
/// 搞若干个网络相关的辅助函数，方便lua环境内使用
/// </summary>
public static class NetHelper
{
    /// <summary>
    /// 主要是使用UnityWebRequest来加载本地文件，由于android系统打包时，文件被压缩到apk包中，
    /// 因此直接System.IO.File来读取是不行的，需要UnityWebRequest来理解apk格式
    /// </summary>
    /// <param name="assetPathInBundle"></param>
    /// <returns></returns>
    public static byte[] UnityWebRequestLocalGet(string assetPathInBundle)
    {
        // Debug.Log($"UnityWebRequest.Get {assetPathInBundle}");
        using (var req = UnityWebRequest.Get(assetPathInBundle))
        {
            req.SendWebRequest();
            
            // 一直等待，由于是本地加载文件，除非文件非常巨大，否则也不会导致卡住Main线程
            while (!req.isDone) ;

            if (req.isHttpError)
            {
                Debug.LogError($"NetHelper.UnityWebRequestLocalGet {assetPathInBundle} failed, error:{req.error}");
            }

            //return data;
            return req.downloadHandler.data;
        }
    }

    /// <summary>
    /// LUA脚本中调用本函数，从APK包中抽取资源到SDCard中
    /// </summary>
    /// <param name="src"></param>
    /// <param name="dst"></param>
    /// <param name="overrided"></param>
    public static void UnityWebRequestLocalCopy(string src, string dst, bool overrided)
    {
        if (System.IO.File.Exists(dst) && !overrided)
        {
            return;
        }

        var bs = UnityWebRequestLocalGet(src);
        System.IO.File.WriteAllBytes(dst, bs);
    }

    public static bool WriteBytesToFile(string path, byte[] bytes)
    {
        bool result = false;
        try
        {
            System.IO.File.WriteAllBytes(path, bytes);
            result = true;
        }
        catch(System.Exception ex)
        {
            Debug.Log(string.Format($"NetHelper.WriteBytesToFile exception:{ex.Message}"));
        }
        
        return result;
    }

    public static string MD5(byte[] bytes)
    {
        if (bytes == null || bytes.Length < 1)
        {
            Debug.LogWarning("NetHelper.MD5 calc MD5 with null or zero length byte array");
            return string.Empty;
        }

        using (var md5Hash = System.Security.Cryptography.MD5.Create())
        {
            // Convert the input string to a byte array and compute the hash.
            byte[] data = md5Hash.ComputeHash(bytes);

            // Create a new Stringbuilder to collect the bytes
            // and create a string.
            StringBuilder sBuilder = new StringBuilder();

            // Loop through each byte of the hashed data 
            // and format each one as a hexadecimal string.
            for (int i = 0; i < data.Length; i++)
            {
                sBuilder.Append(data[i].ToString("x2"));
            }

            // Return the hexadecimal string.
            return sBuilder.ToString();
        }
    }

    public static string NetworkTypeString()
    {

        string tstr = "";

        //Check if the device cannot reach the internet
        if (Application.internetReachability == NetworkReachability.NotReachable)
        {
            //Change the Text
            tstr = "NotReachable";
        }
        //Check if the device can reach the internet via a carrier data network
        else if (Application.internetReachability == NetworkReachability.ReachableViaCarrierDataNetwork)
        {
            tstr = "CarrierDataNetwork";
        }
        //Check if the device can reach the internet via a LAN
        else if (Application.internetReachability == NetworkReachability.ReachableViaLocalAreaNetwork)
        {
            tstr = "LocalAreaNetwork";
        }

        return tstr;
    }

    /// <summary>
    /// 比较两个版本字符串
    /// </summary>
    /// <param name="version1">形式如: v1.0.0</param>
    /// <param name="version2">形式如: v1.0.0</param>
    /// <returns></returns>
    public static int VersionCompare(string version1, string version2)
    {
        var vi1 = VersionString2Integer(version1);
        var vi2 = VersionString2Integer(version2);

        if (vi1 > vi2)
        {
            return 1;
        }

        if (vi1 < vi2)
        {
            return -1;
        }

        return 0;
    }

    /// <summary>
    /// 把形如"v1.0.0"的版本字符串，串接为一个int32
    /// </summary>
    /// <param name="ver"></param>
    /// <returns></returns>
    public static int VersionString2Integer(string ver)
    {
        var vers = ver.Split('.');
        var major = int.Parse(vers[0].Substring(1));
        var minor = int.Parse(vers[1]);
        var hotfix = int.Parse(vers[2]);

        return (major << 24) | (minor << 16) | hotfix;
    }
}
