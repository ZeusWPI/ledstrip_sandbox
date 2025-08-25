module thread_manager;

import ledstrip.ledstrip : Ledstrip;
import script.bf.bf_script_instance : BfScriptInstance;
import script.lua.lua_script_instance : LuaScriptInstance;
import script.python.python_script_instance : PythonScriptInstance;
import script.script_instance : ScriptInstance;
import script.script_instances : ScriptInstances;
import singleton : sharedSingleton;

import core.sys.posix.signal : pthread_kill, pthread_t, SIGHUP;
import core.thread : Thread;
import core.time : msecs;

import std.algorithm : any, find, min;
import std.exception : basicExceptionCtors, enforce, ErrnoException;
import std.format : f = format;
import std.string : fromStringz, toStringz;

import vibe.core.log;

@safe:

private static
T enf(T)(
    T value, lazy const(char)[] msg = "",
    string func = __FUNCTION__, string file = __FILE__, size_t line = __LINE__,
)
    => enforce!ThreadManagerException(value, func ~ ": " ~ msg, file, line);

nothrow @nogc @trusted
bool inMainThread()
    => Thread.getThis.isMainThread;

nothrow
bool inThreadKind(in ThreadKind kind)
{
    try
        return ThreadManager.constInstance.thisThreadKind == kind;
    catch (ThreadManagerException e)
        return false;
    catch (Exception e)
        assert(false);
}

final shared
class ThreadManager
{
    mixin sharedSingleton;

    private __gshared ThreadRegistration[Thread] g_threads;

    private synchronized
    this()
    in (inMainThread)
    {
        registerMainThread;
    }

scope:
    private
    void registerMainThread()
    in (inMainThread)
    {
        logDiagnostic("Registering main thread");
        ThreadRegistration* reg = register(ThreadRegistration(
            Thread.getThis,
            ThreadKind.main,
        ));
        reg.applyName;
    }

    synchronized @trusted
    void startRenderer()
    in (inMainThread)
    in (!g_threads.byValue.any!(reg => reg.kind == ThreadKind.renderer))
    {
        logDiagnostic("Registering renderer thread");
        ThreadRegistration* reg = register(ThreadRegistration(
            new Thread(() => Ledstrip.instance.renderLoop),
            ThreadKind.renderer,
        ));
        logInfo("Starting renderer thread");
        (() @trusted => reg.thread.start)();
        reg.applyName;
    }

    synchronized @trusted
    void startThreadManager()
    in (inMainThread)
    in (!g_threads.byValue.any!(reg => reg.kind == ThreadKind.threadManager))
    {
        logDiagnostic("Registering threadManager thread");
        ThreadRegistration* reg = register(ThreadRegistration(
            new Thread(() => typeof(this).instance.threadManagerThreadEntrypoint),
            ThreadKind.threadManager,
        ));
        logInfo("Starting threadManager thread");
        (() @trusted => reg.thread.start)();
        reg.applyName;
    }

    synchronized
    void createScriptInstanceThread(ScriptInstance scriptInstance)
    in (inMainThread || inThreadKind(ThreadKind.threadManager)) // Webserver or autostart
    in (scriptInstance !is null)
    {
        enf(
            getRegisteredThreadForScriptInstance(scriptInstance) is null,
            f!`Thread for script instance "%s" already exists`(scriptInstance.name),
        );
        const entrypoint = scriptInstance.threadEntrypoint();
        assert(entrypoint !is null);

        logDiagnostic(`Registering thread for script instance "%s"`, scriptInstance.name);
        ThreadRegistration* reg = register(ThreadRegistration(
            new Thread(() => entrypoint(scriptInstance)),
            ThreadKind.scriptInstance,
            scriptInstance,
        ));
        logInfo(`Starting thread for script instance "%s"`, scriptInstance.name);
        (() @trusted => reg.thread.start)();
        reg.applyName;
    }

    synchronized @trusted
    void destroyScriptInstanceThread(ScriptInstance scriptInstance)
    in (inMainThread || inThreadKind(ThreadKind.threadManager)) // Webserver or cleanup
    in (scriptInstance !is null)
    {
        auto thread = getRegisteredThreadForScriptInstance(scriptInstance);
        enf(thread !is null, f!`Thread for script instance "%s" doesn't exists`(scriptInstance.name));
        if (thread.isRunning)
        {
            logInfo(`Stopping thread for script instance "%s"`, scriptInstance.name);
            thread.kill;
        }

        logDiagnostic(`Unregistering thread for script instance "%s"`, scriptInstance.name);
        unregister(thread);
    }

    private @trusted
    void threadManagerThreadEntrypoint()
    in (inThreadKind(ThreadKind.threadManager))
    {
        while (true)
        {
            ScriptInstances.instance.autoStartNeeded;
            cleanupStoppedThreads;
            Thread.sleep(100.msecs);
        }
    }

    private synchronized @trusted
    void cleanupStoppedThreads()
    in (inThreadKind(ThreadKind.threadManager))
    {
        do
        {
            auto match = g_threads.byKey.find!(t => !t.isRunning);
            if (!match.empty)
            {
                ScriptInstance scriptInstance = g_threads[match.front].scriptInstance;
                if (scriptInstance)
                {
                    synchronized (scriptInstance)
                        unregister(match.front);
                }
                else
                    unregister(match.front);
                continue;
            }
        }
        while (false);
    }

    synchronized @trusted
    ThreadKind thisThreadKind() const
    {
        ThreadRegistration* reg = Thread.getThis in g_threads;
        enf(reg !is null, "Called from an unregistered thread");
        return reg.kind;
    }

    private nothrow @nogc synchronized @trusted
    Thread getRegisteredThreadForScriptInstance(in ScriptInstance scriptInstance)
    {
        foreach (ref ThreadRegistration reg; g_threads.byValue)
            if (reg.scriptInstance is scriptInstance)
                return reg.thread;
        return null;
    }

    private synchronized @trusted
    bool isRegistered(scope Thread thread) const
    {
        return (thread in g_threads) !is null;
    }

    private synchronized @trusted
    ThreadRegistration* register(ThreadRegistration reg)
    {
        enf(!isRegistered(reg.thread), "Thread already registered");
        g_threads[reg.thread] = reg;
        return reg.thread in g_threads;
    }

    private synchronized @trusted
    void unregister(Thread thread)
    {
        enf(isRegistered(thread), "Thread not registered");
        ThreadRegistration* reg = thread in g_threads;
        if (reg.kind == ThreadKind.scriptInstance)
            reg.scriptInstance.setStopped;
        g_threads.remove(thread);
    }
}

enum ThreadKind
{
    main,
    renderer,
    threadManager,
    scriptInstance,
}

class ThreadManagerException : Exception
{
    mixin basicExceptionCtors;
}

private
struct ThreadRegistration
{
    private
    {
        Thread m_thread;
        ThreadKind m_kind;
        ScriptInstance m_scriptInstance;
    }

    this(Thread thread, ThreadKind kind, ScriptInstance scriptInstance = null)
    in
    {
        assert(thread !is null);
        if (kind == ThreadKind.scriptInstance)
            assert(scriptInstance !is null);
    }
    do
    {
        m_thread = thread;
        m_kind = kind;
        m_scriptInstance = scriptInstance;
    }

scope:
    void applyName()
    {
        const string name = determineName;
        thread.name = name;
        thread.setPthreadName(name);
    }

    private pure
    string determineName() const
    {
        final switch (m_kind)
        {
        case ThreadKind.main:
            return "main";
        case ThreadKind.threadManager:
            return "threadManager";
        case ThreadKind.renderer:
            return "renderer";
        case ThreadKind.scriptInstance:
            return m_scriptInstance.extension[1 .. $] ~ " " ~ m_scriptInstance.name;
        }
    }

pure nothrow @nogc:
    Thread thread() => m_thread;
    ThreadKind kind() => m_kind;
    ScriptInstance scriptInstance() => m_scriptInstance;
}

enum size_t ct_maxThreadNameLength = 15;

private extern(C) @system nothrow @nogc
{
    /// ditto
    int pthread_setname_np(pthread_t thread, const char *name);
}

private @trusted
void setPthreadName(scope Thread thread, string name)
{
    immutable(char)* namez = name[0 .. min($, ct_maxThreadNameLength)].toStringz;
    if (pthread_setname_np(thread.id, namez) != 0)
        throw new ErrnoException("setThreadName: pthread_setname_np failed");
}

private @system
void kill(scope Thread thread)
{
    int ret = pthread_kill(thread.id, SIGHUP);
    assert(ret == 0);
}
