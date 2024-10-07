module script.scripts;

import data_dir : DataDir;
import script.bf.bf_script : BfScript;
import script.lua.lua_script : LuaScript;
import script.script : Script, ScriptExtension;
import singleton : sharedSingleton;
import thread_manager : ThreadManager;

import core.time : msecs, seconds;

import std.algorithm : endsWith;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;

import vibe.core.core : runTask, sleep;
import vibe.core.log;

@safe:

final shared
class Scripts
{
    mixin sharedSingleton;

    private alias enf = enforce!ScriptsException;

    private shared Script[string] m_scripts;

    private
    this()
    {
        loadConfigScripts;
    }

    private
    void loadConfigScripts()
    {
        const configScripts = DataDir.constInstance.config.scripts;
        foreach (configScriptName, configScript; configScripts)
        {
            try
            {
                createScript(
                    configScriptName,
                    configScript.fileName,
                    configScript.ledCount,
                    configScript.autoStart,
                );
            }
            catch (Exception e)
            {
                logError(
                    `Failed loading script "%s" from config: %s`,
                    configScriptName, (() @trusted => e.toString)(),
                );
            }
        }
    }

    synchronized
    void startAutoStartTask()
    in (ThreadManager.constInstance.inMainThread, "Scripts: startAutoStartTask must be called from main thread")
    {
        runTask((Scripts scripts) => scripts.autoStartTask, this);
    }

    private nothrow
    void autoStartTask()
    in (ThreadManager.constInstance.inMainThread, "Scripts: autoStartTask must be called from main thread")
    {
        try
        {
            bool[Script] alreadyStarted;
            while (true)
            {
                try
                {
                    synchronized
                    {
                        foreach (name, script; m_scripts)
                        {
                            if (script.autoStart && script !in alreadyStarted)
                            {
                                startScript(name);
                                alreadyStarted[script] = true;
                            }
                        }
                    }
                    sleep(200.msecs);
                }
                catch (Exception e)
                {
                    logError("autoStartTask iteration failed: %s", (() @trusted => e.toString)());
                    sleep(1.seconds);
                }
            }
        }
        catch (Exception e)
        {
            logError("autoStartTask exited with exception: %s", (() @trusted => e.toString)());
        }
    }

    inout(shared(Script[string])) scripts() inout
        => m_scripts;

    synchronized
    const(Script) createScript(string name, string fileName, uint ledCount, bool autoStart)
    {
        Script script;
        if (fileName.endsWith(cast(string) ScriptExtension.lua))
            script = new LuaScript(name, fileName, ledCount, autoStart);
        else if (fileName.endsWith(cast(string) ScriptExtension.bf))
            script = new BfScript(name, fileName, ledCount, autoStart);
        else
            throw new Exception(f!`createScript: Unknown script type for file name "%s"`(fileName));
        m_scripts[name] = script;
        return script;
    }

    synchronized
    void startScript(string name)
    {
        enf(name in m_scripts, f!`startScript: No script with name "%s"`(name));
        m_scripts[name].setRunning;
        ThreadManager.instance.addAndStartScriptTask(m_scripts[name]);
    }

    synchronized
    void stopScript(string name)
    {
        enf(name in m_scripts, f!`stopScript: No script with name "%s"`(name));
        m_scripts[name].setStopped;
        ThreadManager.instance.stopAndRemoveScriptTask(m_scripts[name]);
    }

    synchronized
    void removeScript(string name)
    {
        enf(name in m_scripts, f!`removeScript: No script with name "%s"`(name));
        stopScript(name);
        m_scripts.remove(name);
    }
}

class ScriptsException : Exception
{
    mixin basicExceptionCtors;
}
