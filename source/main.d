module main;

import core.memory : GC;
import core.stdc.stdlib : exit;

import std.exception : enforce;

import data_dir : DataDir;
import ledstrip.ledstrip : Ledstrip;
import ledstrip.ledstrip_states : LedstripStates;
import mailbox : Mailbox;
import mqtt : Mqtt;
import script.script_instances : ScriptInstances;
import thread_manager : ThreadManager;
import webserver.webserver : Webserver;

import vibe.core.core : disableDefaultSignalHandlers, runApplication;
import vibe.core.log;
import vibe.core.path;
import vibe.core.process : Config, execute, spawnProcess;

@safe:

extern(C) __gshared string[] rt_options = [ "gcopt=parallel:0" ];

int main()
{
    try
    {
        (() @trusted {
            disableDefaultSignalHandlers;
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
        
        return runApplication;
    }
    catch (Exception e)
    {
        (() @trusted {
            logError("Error in main thread: ", e.toString);
            exit(1); // Kill other threads
        })();
        assert(false);
    }
}

@system
void registerSignalHandlers()
{
    import core.sys.posix.stdlib : _Exit;
    import core.sys.posix.pthread : pthread_exit;
    import core.sys.posix.signal : sigaction, sigaction_t, sigemptyset, SIGHUP, SIGINT, SIGTERM;

    extern (C)
    static void handler(int sig)
    {
        switch (sig)
        {
        case SIGHUP:
            pthread_exit(null);
            assert(false);
        default:
            _Exit(1);
            assert(false);
        }
    }
    
    extern (C)
    static void handler_exit_thread(int)
    {
    }

    sigaction_t sa;
    sa.sa_handler = &handler;
    sigemptyset(&sa.sa_mask);
    enforce(sigaction(SIGHUP, &sa, null) == 0);
    enforce(sigaction(SIGINT, &sa, null) == 0);
    enforce(sigaction(SIGTERM, &sa, null) == 0);
}