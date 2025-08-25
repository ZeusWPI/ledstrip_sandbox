module data_dir;

import config : Config;
import script.script_instance : isValidScriptSourceFileName;
import singleton : threadLocalSingleton;
import thread_manager : inMainThread;

import std.algorithm : endsWith, filter, map;
import std.array : array;
import std.exception : basicExceptionCtors, enforce;
import std.file : dirEntries, DirEntry, exists, isDir, isFile, mkdir, readText, remove, SpanMode, write;
import std.format : f = format;
import std.path : baseName, buildPath;

import vibe.data.json : deserializeJson, serializeToPrettyJson;

@safe:

final
class DataDir
{
    mixin threadLocalSingleton;

    private enum string ct_dirName = "data";
    private enum string ct_jsonFileName = "config.json";
    private enum string ct_jsonFilePath = buildPath(ct_dirName, ct_jsonFileName);

    private static shared Config s_config;
    private Config m_config;

    private
    this()
    in (inMainThread, "DataDir: ctor must be called from main thread")
    {
        loadConfig;
    }

    private
    void loadConfig()
    {
        createIfNeeded;
        m_config = deserializeJson!Config(ct_jsonFilePath.readText);
        syncConfigToSharedStatic;
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
    ref inout(Config) config() inout
        => m_config;

    static nothrow @nogc
    ref const(shared(Config)) sharedConfig()
        => s_config;

    void syncConfigToSharedStatic()
    {
        s_config = m_config.sharedDup;
    }

    void saveConfig()
    {
        syncConfigToSharedStatic;
        createIfNeeded;
        ct_jsonFilePath.write(m_config.serializeToPrettyJson);
    }

    @trusted
    string[] listScriptSourceFiles() const
    {
        return dirEntries(ct_dirName, SpanMode.shallow)
            .filter!(entry => entry.isFile)
            .map!(entry => entry.name.baseName)
            .filter!(name => name.isValidScriptSourceFileName)
            .array;
    }

    string loadScriptSourceFile(string sourceFileName) const
    {
        string scriptSourceFilePath = getScriptSourceFilePath(sourceFileName);
        enforce!DataDirException(
            scriptSourceFilePath.exists,
            f!`loadScriptSourceFile: Script source file "%s" doesn't exist`(sourceFileName),
        );
        enforce!DataDirException(
            scriptSourceFilePath.isFile,
            f!`loadScriptSourceFile: Script source file "%s" is not a regular file`(sourceFileName),
        );
        return scriptSourceFilePath.readText;
    }

    void saveScriptSourceFile(string sourceFileName, string sourceCode) const
    {
        string scriptSourceFilePath = getScriptSourceFilePath(sourceFileName);
        if (scriptSourceFilePath.exists)
        {
            enforce!DataDirException(
                scriptSourceFilePath.isFile,
                f!`saveScriptSourceFile: Script source file "%s" is not a regular file`(sourceFileName),
            );
        }
        scriptSourceFilePath.write(sourceCode);
    }

    void deleteScriptSourceFile(string sourceFileName) const
    {
        string scriptSourceFilePath = getScriptSourceFilePath(sourceFileName);
        enforce!DataDirException(
            scriptSourceFilePath.exists,
            f!`deleteScriptSourceFile: Script source file "%s" doesn't exist`(sourceFileName),
        );
        enforce!DataDirException(
            scriptSourceFilePath.isFile,
            f!`deleteScriptSourceFile: Script source file "%s" is not a regular file`(sourceFileName),
        );
        scriptSourceFilePath.remove;
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
    string getScriptSourceFilePath(string sourceFileName) const
    {
        createIfNeeded;
        enforce!DataDirException(
            sourceFileName.isValidScriptSourceFileName,
            f!`Invalid script source file name "%s"`(sourceFileName),
        );
        return buildPath(ct_dirName, sourceFileName);
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
