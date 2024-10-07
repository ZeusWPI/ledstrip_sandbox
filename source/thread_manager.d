module thread_manager;

import script.script : Script;
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
    private TaskPool m_scriptTaskPool;
    private Task[Script] m_scriptTasks;

    private nothrow
    this()
    {
        uint scriptTaskPoolThreadCount = logicalProcessorCount > 1 ? logicalProcessorCount - 1 : 1;
        m_scriptTaskPool = new TaskPool(scriptTaskPoolThreadCount, "scriptTaskPool");
    }

    nothrow @nogc @trusted
    bool inMainThread() const
        => Thread.getThis.isMainThread;

    nothrow
    bool inScriptTaskPool() const
    {
        // TODO: Find a better solution.
        // Note: task might not be in m_scriptTasks at this point.
        return !inMainThread;
    }

    synchronized
    void addAndStartScriptTask(Script script)
    {
        enf(
            script !in m_scriptTasks,
            f!`addAndStartScriptTask: Task for script "%s" already exists`(script.name),
        );
        logDiagnostic(`Starting task for script "%s"`, script.name);
        Task task = m_scriptTaskPool.runTaskH(script.taskEntrypoint, script);
        m_scriptTasks[script] = task;
    }

    synchronized
    void stopAndRemoveScriptTask(Script script)
    {
        enf(
            script in m_scriptTasks,
            f!`stopAndRemoveScriptTask: Task for script "%s" doesn't exists`(script.name),
        );
        Task task = m_scriptTasks[script];
        if (task.running)
            task.interrupt;
        m_scriptTasks.remove(script);
    }
}

class ThreadManagerException : Exception
{
    mixin basicExceptionCtors;
}
