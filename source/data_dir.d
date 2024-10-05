module data_dir;

import config : Config;
import script.script : isValidScriptFileName;

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

    string loadScript(string fileName)
    {
        string scriptFilePath = getScriptFilePath(fileName);
        enforce!DataDirException(
            scriptFilePath.exists,
            f!`loadScript: Script file %s doesn't exist`(fileName),
        );
        enforce!DataDirException(
            scriptFilePath.isFile,
            f!`loadScript: Script file %s is not a regular file`(fileName),
        );
        return scriptFilePath.readText;
    }

    void saveScript(string fileName, string sourceCode)
    {
        string scriptFilePath = getScriptFilePath(fileName);
        if (scriptFilePath.exists)
        {
            enforce!DataDirException(
                scriptFilePath.isFile,
                f!`saveScript: Script file %s is not a regular file`(fileName),
            );
        }
        scriptFilePath.write(sourceCode);
    }

    private
    string getScriptFilePath(string fileName)
    {
        createIfNeeded;
        enforce!DataDirException(
            fileName.isValidScriptFileName,
            f!`Invalid script file name "%s"`(fileName),
        );
        return buildPath(ct_dirName, fileName);
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
