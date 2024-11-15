module thread_manager;

import script.script_instance : ScriptInstance;
import singleton : sharedSingleton;

import core.thread : Thread;

import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;

import vibe.core.core : logicalProcessorCount;
import vibe.core.log;
import vibe.core.task : Task;
import vibe.core.taskpool : TaskPool;

@safe:

final shared
class ThreadManager
{
    mixin sharedSingleton;

    private alias enf = enforce!ThreadManagerException;
    private TaskPool m_scriptInstanceTaskPool;
    private Task[ScriptInstance] m_scriptInstanceTasks;

    private synchronized nothrow
    this()
    {
        // uint scriptTaskPoolThreadCount = logicalProcessorCount > 1 ? logicalProcessorCount - 1 : 1;
        uint scriptInstanceTaskPoolThreadCount = 1;
        m_scriptInstanceTaskPool = new TaskPool(scriptInstanceTaskPoolThreadCount, "scriptInstanceTaskPool");
    }

    nothrow @nogc @trusted
    bool inMainThread() const
        => Thread.getThis.isMainThread;

    nothrow
    bool inScriptInstanceTaskPool() const
    {
        // TODO: Find a better solution.
        // Note: task might not be in m_scriptInstanceTasks at this point.
        return !inMainThread;
    }

    synchronized
    void addAndStartScriptInstanceTask(ScriptInstance scriptInstance)
    {
        enf(
            scriptInstance !in m_scriptInstanceTasks,
            f!`addAndStartScriptInstanceTask: Task for script instance "%s" already exists`(
                scriptInstance.name,
        ),
        );
        logDiagnostic(`Starting task for script instance "%s"`, scriptInstance.name);
        Task task = m_scriptInstanceTaskPool.runTaskH(scriptInstance.taskEntrypoint, scriptInstance);
        m_scriptInstanceTasks[scriptInstance] = task;
    }

    synchronized
    void stopAndRemoveScriptInstanceTask(ScriptInstance scriptInstance)
    {
        enf(
            scriptInstance in m_scriptInstanceTasks,
            f!`stopAndRemoveScriptInstanceTask: Task for script instance "%s" doesn't exists`(
                scriptInstance.name,
        ),
        );
        Task task = m_scriptInstanceTasks[scriptInstance];
        if (task.running)
            task.interrupt;
        m_scriptInstanceTasks.remove(scriptInstance);
    }
}

class ThreadManagerException : Exception
{
    mixin basicExceptionCtors;
}
