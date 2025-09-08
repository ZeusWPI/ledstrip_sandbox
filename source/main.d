module main;

import data_dir : DataDir;
import ledstrip.ledstrip : Ledstrip;
import ledstrip.ledstrip_states : LedstripStates;
import mailbox : Mailbox;
import mqtt : Mqtt;
import script.script_instances : ScriptInstances;
import thread_manager : inMainThread, inThreadKind, ThreadKind, ThreadManager;
import webserver.webserver : Webserver;

import core.atomic : atomicLoad, atomicStore;
import core.stdc.stdlib : _Exit;
import core.time : msecs;

import std.exception : enforce;

import vibe.core.core : runEventLoopOnce;
import vibe.core.log;
import vibe.core.path;
import vibe.core.process : spawnProcess;

@safe:

extern(C) __gshared string[] rt_options = [ "gcopt=parallel:0" ];

shared bool g_exitMain = false;

int main()
{
    int ret = 0;
    scope (exit)
    {
        logWarn("main: Exiting with status %d.", ret);
        (() @trusted => _Exit(ret))();
    }

    try
    {
        (() @trusted {
            registerSignalHandlers;
        })();

        setLogLevel(LogLevel.diagnostic);
        setLogFormat(FileLogger.Format.thread, FileLogger.Format.thread);

        // These have no dependencies
        ThreadManager.createInstance;
        Mailbox.createInstance;

        // These depend on ThreadManager
        DataDir.createInstance;

        // These depend on DataDir and/or ThreadManager
        Mqtt.createInstance;
        ScriptInstances.createInstance;
        LedstripStates.createInstance;
        Ledstrip.createInstance;
        Webserver.createInstance;

        Webserver.instance.start;
        ThreadManager.instance.startRenderer;
        ThreadManager.instance.startThreadManager;

        // TODO: manage, auto restart if it crashes...
        try spawnProcess(["node", "luals/ws-wrapper.js"]);
        catch (Exception e) logWarn("Failed to spawn luals");
        
        while (!g_exitMain.atomicLoad)
            runEventLoopOnce(100.msecs);
    }
    catch (Exception e)
    {
        logError("Error in main thread: ", (() @trusted => e.toString)());
        ret = 1;
    }

    logWarn("main: Reaper was awakened, killing all threads.");
    ThreadManager.instance.killAllButMain;
}

@trusted
void registerSignalHandlers()
{
    import core.sys.posix.pthread : pthread_exit;
    import core.sys.posix.signal : sigaction, sigaction_t, sigemptyset, SIGHUP, SIGINT, SIGTERM;

    extern (C) nothrow
    static void signalHandler(int sig)
    {
        final switch (sig)
        {
        case SIGHUP:
            logWarn("signalHandler: Interpreting SIGHUP as just exit this thread.");
            logWarn("signalHandler: Calling pthread_exit.");
            pthread_exit(null);
            assert(false);
        case SIGINT:
        case SIGTERM:
            logWarn("signalHandler: Interpreting SIGINT/TERM as exit application.");
            logWarn("signalHandler: Awakening the reaper.");
            g_exitMain.atomicStore(true);
            return;
        }
    }
    
    sigaction_t sa;
    sa.sa_handler = &signalHandler;
    sigemptyset(&sa.sa_mask);
    enforce(sigaction(SIGHUP, &sa, null) == 0);
    enforce(sigaction(SIGINT, &sa, null) == 0);
    enforce(sigaction(SIGTERM, &sa, null) == 0);
}
