module data_dir;

import config : Config;
import script.script : isValidScriptFileName;
import singleton : sharedSingleton;

import std.algorithm : endsWith, filter, map;
import std.array : array;
import std.exception : basicExceptionCtors, enforce;
import std.file : dirEntries, DirEntry, exists, isDir, isFile, mkdir, readText, SpanMode, write;
import std.format : f = format;
import std.path : baseName, buildPath;

import vibe.data.json : deserializeJson, serializeToPrettyJson;

@safe:

final shared
class DataDir
{
    mixin sharedSingleton;

    private enum string ct_dirName = "data";
    private enum string ct_jsonFileName = "config.json";
    private enum string ct_jsonFilePath = buildPath(ct_dirName, ct_jsonFileName);

    private Config m_config;

    private
    this()
    {
        loadConfig;
    }

    private synchronized
    void loadConfig()
    {
        createIfNeeded;
        m_config = deserializeJson!Config(ct_jsonFilePath.readText).sharedDup;
        enforce(
            isValidFps(m_config.fps),
            f!`loadConfig: invalid fps "%s"`(m_config.fps)
        );
        enforce(
            isValidLedCount(m_config.ledCount),
            f!`loadConfig: invalid ledCount "%s"`(m_config.ledCount)
        );
    }

    pure nothrow @nogc
    ref inout(shared(Config)) config() inout
        => m_config;

    synchronized
    void saveConfig() const
    {
        createIfNeeded;
        ct_jsonFilePath.write(m_config.serializeToPrettyJson);
    }

    synchronized @trusted
    string[] listScripts() const
    {
        return dirEntries(ct_dirName, SpanMode.shallow)
            .filter!(entry => entry.isFile)
            .map!(entry => entry.name.baseName)
            .filter!(name => name.isValidScriptFileName)
            .array;
    }

    synchronized
    string loadScript(string fileName) const
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

    synchronized
    void saveScript(string fileName, string sourceCode) const
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
    void createIfNeeded() const
    {
        if (!ct_dirName.exists)
            mkdir(ct_dirName);
        enforce!DataDirException(
            ct_dirName.isDir,
            f!"%s is not a directory"(ct_dirName),
        );

        if (!ct_jsonFilePath.exists)
            ct_jsonFilePath.write(Config.init.serializeToPrettyJson);
        enforce!DataDirException(
            ct_jsonFilePath.isFile,
            f!"%s is not a regular file"(ct_jsonFilePath),
        );
    }

    private
    string getScriptFilePath(string fileName) const
    {
        createIfNeeded;
        enforce!DataDirException(
            fileName.isValidScriptFileName,
            f!`Invalid script file name "%s"`(fileName),
        );
        return buildPath(ct_dirName, fileName);
    }

    static
    bool isValidLedCount(uint ledCount)
        => ledCount > 0;

    static
    bool isValidFps(uint fps)
        => fps > 0;
}

class DataDirException : Exception
{
    mixin basicExceptionCtors;
}
