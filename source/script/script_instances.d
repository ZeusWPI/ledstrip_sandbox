module script.script_instances;

import data_dir : DataDir;
import script.bf.bf_script_instance : BfScriptInstance;
import script.lua.lua_script_instance : LuaScriptInstance;
import script.python.python_script_instance : PythonScriptInstance;
import script.script_instance : ScriptExtension, ScriptInstance;
import singleton : sharedSingleton;
import thread_manager : inMainThread, inThreadKind, ThreadKind, ThreadManager;

import core.thread : Thread;

import std.algorithm : endsWith;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;

import vibe.core.log;

@safe:

private static
T enf(T)(
    T value, lazy const(char)[] msg = "",
    string func = __FUNCTION__, string file = __FILE__, size_t line = __LINE__,
)
    => enforce!ScriptInstancesException(value, func ~ ": " ~ msg, file, line);

final shared
class ScriptInstances
{
    mixin sharedSingleton;

    private shared ScriptInstance[string] m_scriptInstances;

    private synchronized
    this()
    in (inMainThread)
    {
        loadConfigScriptInstances;
    }

    private synchronized
    void loadConfigScriptInstances()
    in (inMainThread)
    {
        const configScriptInstances = DataDir.sharedConfig.scriptInstances;
        foreach (configScriptInstanceName, configScriptInstance; configScriptInstances)
        {
            try
            {
                createScriptInstance(
                    configScriptInstanceName,
                    configScriptInstance.sourceFileName,
                    configScriptInstance.ledCount,
                    configScriptInstance.autoStart,
                );
            }
            catch (Exception e)
            {
                logError(
                    `Failed loading script instance "%s" from config: %s`,
                    configScriptInstanceName, (() @trusted => e.toString)(),
                );
            }
        }
    }

    synchronized
    inout(shared(ScriptInstance[string])) scriptInstances() inout
        => m_scriptInstances;

    synchronized
    const(ScriptInstance) createScriptInstance(string name, string sourceFileName, uint ledCount, bool autoStart)
    {
        enf(name !in m_scriptInstances, f!`Script instance with name "%s" already exists`(name));
        ScriptInstance scriptInstance;
        if (sourceFileName.endsWith(cast(string) ScriptExtension.lua))
            scriptInstance = new LuaScriptInstance(name, sourceFileName, ledCount, autoStart);
        // else if (sourceFileName.endsWith(cast(string) ScriptExtension.python))
        //     scriptInstance = new PythonScriptInstance(name, sourceFileName, ledCount, autoStart);
        else if (sourceFileName.endsWith(cast(string) ScriptExtension.bf))
            scriptInstance = new BfScriptInstance(name, sourceFileName, ledCount, autoStart);
        else
            enf(false, f!`Unknown script type for file name "%s"`(sourceFileName));
        m_scriptInstances[name] = scriptInstance;
        return scriptInstance;
    }

    synchronized
    void removeScriptInstance(string name)
    {
        enf(name in m_scriptInstances, f!`No script instance with name "%s"`(name));
        enf(!m_scriptInstances[name].running, f!`Script instance "%s" is still running`(name));
        m_scriptInstances.remove(name);
    }

    synchronized
    void startScriptInstance(string name)
    {
        enf(name in m_scriptInstances, f!`No script instance with name "%s"`(name));
        enf(!m_scriptInstances[name].running, f!`Script instance "%s" is already running`(name));
        m_scriptInstances[name].setRunning;
        ThreadManager.instance.createScriptInstanceThread(m_scriptInstances[name]);
    }

    synchronized
    void stopScriptInstance(string name)
    {
        enf(name in m_scriptInstances, f!`No script instance with name "%s"`(name));
        enf(m_scriptInstances[name].running, f!`Script instance "%s" is already stopped`(name));
        m_scriptInstances[name].setStopped;
        ThreadManager.instance.destroyScriptInstanceThread(m_scriptInstances[name]);
    }

    synchronized
    void reloadScriptInstance(string name)
    {
        enf(name in m_scriptInstances, f!`No script instance with name "%s"`(name));
        enf(!m_scriptInstances[name].running, f!`Script instance "%s" must be stopped first`(name));
        ScriptInstance oldScriptInstance = m_scriptInstances[name];
        scope (failure)
        {
            m_scriptInstances[name] = oldScriptInstance;
        }
        removeScriptInstance(name);
        createScriptInstance(
            oldScriptInstance.name,
            oldScriptInstance.sourceFileName,
            oldScriptInstance.ledCount,
            oldScriptInstance.autoStart,
        );
        if (oldScriptInstance.autoStart)
        {
            startScriptInstance(name);
        }
    }

    synchronized nothrow
    void autoStartNeeded()
    in (inThreadKind(ThreadKind.threadManager))
    {
        try
        {
            foreach (name, scriptInstance; m_scriptInstances)
                if (!scriptInstance.startedOnce && scriptInstance.autoStart)
                    startScriptInstance(name);
        }
        catch (Exception e)
        {
            logError("autoStartNeeded failed: %s", (() @trusted => e.toString)());
        }
    }
}

class ScriptInstancesException : Exception
{
    mixin basicExceptionCtors;
}
