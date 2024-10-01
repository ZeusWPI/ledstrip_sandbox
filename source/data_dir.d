module data_dir;

import config : Config;

import std.algorithm : canFind;
import std.exception : basicExceptionCtors, enforce;
import std.file : exists, isDir, isFile, mkdir, readText, write;
import std.format : f = format;
import std.path : buildPath;

@safe:

struct DataDir
{
    private enum ct_dirName = "data";
    private enum ct_jsonFileName = "config.json";
    private enum ct_jsonFilePath = buildPath(ct_dirName, ct_jsonFileName);

    @disable this();
    @disable this(ref typeof(this));

static:
    Config loadConfig()
    {
        createIfNeeded;
        return Config.fromJsonString(ct_jsonFilePath.readText);
    }

    void saveConfig(Config c)
    {
        createIfNeeded;
        c.toJsonString.write(ct_jsonFilePath);
    }

    string loadScript(string scriptFileName)
    {
        string scriptFilePath = getScriptFilePath(scriptFileName);
        enforce!DataDirException(
            scriptFilePath.exists,
            f!`loadScript: Script file %s doesn't exist`(scriptFileName),
        );
        enforce!DataDirException(
            scriptFilePath.isFile,
            f!`loadScript: Script file %s is not a regular file`(scriptFileName),
        );
        return scriptFilePath.readText;
    }

    void saveScript(string scriptFileName, string scriptString)
    {
        string scriptFilePath = getScriptFilePath(scriptFileName);
        if (scriptFilePath.exists)
        {
            enforce!DataDirException(
                scriptFilePath.isFile,
                f!`saveScript: Script file %s is not a regular file`(scriptFileName),
            );
        }
        scriptFilePath.write(scriptString);
    }

    private
    string getScriptFilePath(string scriptFileName)
    {
        createIfNeeded;
        enforce!DataDirException(
            !scriptFileName.canFind("/"),
            f!`Script file name "%s" cannot contain /`(scriptFileName),
        );
        return buildPath(ct_dirName, scriptFileName);
    }

    private
    void createIfNeeded()
    {
        if (!ct_dirName.exists)
            mkdir(ct_dirName);
        enforce!DataDirException(
            ct_dirName.isDir,
            f!"%s is not a directory"(ct_dirName),
        );

        if (!ct_jsonFilePath.exists)
            ct_jsonFilePath.write(Config.init.toJsonString);
        enforce!DataDirException(
            ct_jsonFilePath.isFile,
            f!"%s is not a regular file"(ct_jsonFilePath),
        );
    }
}

class DataDirException : Exception
{
    mixin basicExceptionCtors;
}
