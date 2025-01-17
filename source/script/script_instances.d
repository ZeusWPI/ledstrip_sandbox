module script.script_instances;

import data_dir : DataDir;
import script.bf.bf_script_instance : BfScriptInstance;
import script.lua.lua_script_instance : LuaScriptInstance;
import script.python.python_script_instance : PythonScriptInstance;
import script.script_instance : ScriptInstance, ScriptExtension;
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
class ScriptInstances
{
    mixin sharedSingleton;

    private alias enf = enforce!ScriptInstancesException;

    private shared ScriptInstance[string] m_scriptInstances;

    private
    this()
    {
        loadConfigScriptInstances;
    }

    private
    void loadConfigScriptInstances()
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
    void startAutoStartTask()
    in (ThreadManager.constInstance.inMainThread, "ScriptInstances: startAutoStartTask must be called from main thread")
    {
        runTask((ScriptInstances scriptInstances) => scriptInstances.autoStartTask, this);
    }

    private nothrow
    void autoStartTask()
    in (ThreadManager.constInstance.inMainThread, "ScriptInstances: autoStartTask must be called from main thread")
    {
        try
        {
            // TODO: reimplement: keeping this around will prevent gc of removed script instances
            bool[ScriptInstance] alreadyStarted;
            while (true)
            {
                try
                {
                    synchronized
                    {
                        foreach (name, scriptInstance; m_scriptInstances)
                        {
                            if (scriptInstance.autoStart && scriptInstance !in alreadyStarted)
                            {
                                if (!scriptInstance.running)
                                    startScriptInstance(name);
                                alreadyStarted[scriptInstance] = true;
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

    inout(shared(ScriptInstance[string])) scriptInstances() inout
        => m_scriptInstances;

    synchronized
    const(ScriptInstance) createScriptInstance(string name, string sourceFileName, uint ledCount, bool autoStart)
    {
        enf(
            name !in m_scriptInstances,
            f!`createScriptInstance: Script instance with name "%s" already exists`(name),
        );
        ScriptInstance scriptInstance;
        if (sourceFileName.endsWith(cast(string) ScriptExtension.lua))
            scriptInstance = new LuaScriptInstance(name, sourceFileName, ledCount, autoStart);
        // else if (sourceFileName.endsWith(cast(string) ScriptExtension.python))
        //     scriptInstance = new PythonScriptInstance(name, sourceFileName, ledCount, autoStart);
        else if (sourceFileName.endsWith(cast(string) ScriptExtension.bf))
            scriptInstance = new BfScriptInstance(name, sourceFileName, ledCount, autoStart);
        else
        {
            throw new ScriptInstancesException(
                f!`createScriptInstance: Unknown script type for file name "%s"`(sourceFileName),
            );
        }
        m_scriptInstances[name] = scriptInstance;
        return scriptInstance;
    }

    synchronized
    void removeScriptInstance(string name)
    {
        enf(
            name in m_scriptInstances,
            f!`removeScriptInstance: No script instance with name "%s"`(name),
        );
        enf(
            !m_scriptInstances[name].running,
            f!`removeScriptInstance: Script instance "%s" is still running`(name),
        );
        m_scriptInstances.remove(name);
    }

    synchronized
    void startScriptInstance(string name)
    {
        enf(
            name in m_scriptInstances,
            f!`startScriptInstance: No script instance with name "%s"`(name),
        );
        enf(
            !m_scriptInstances[name].running,
            f!`startScriptInstance: Script instance "%s" is already running`(name),
        );
        m_scriptInstances[name].setRunning;
        ThreadManager.instance.addAndStartScriptInstanceTask(m_scriptInstances[name]);
    }

    synchronized
    void stopScriptInstance(string name)
    {
        enf(
            name in m_scriptInstances,
            f!`stopScriptInstance: No script instance with name "%s"`(name),
        );
        enf(
            m_scriptInstances[name].running,
            f!`stopScriptInstance: Script instance "%s" is already stopped`(name),
        );
        m_scriptInstances[name].setStopped;
        ThreadManager.instance.stopAndRemoveScriptInstanceTask(m_scriptInstances[name]);
    }

    synchronized
    void reloadScriptInstance(string name)
    {
        enf(
            name in m_scriptInstances,
            f!`reloadScriptInstance: No script instance with name "%s"`(name),
        );
        enf(
            !m_scriptInstances[name].running,
            f!`reloadScriptInstance: Script instance "%s" must be stopped first`(name),
        );
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
}

class ScriptInstancesException : Exception
{
    mixin basicExceptionCtors;
}
