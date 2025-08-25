module main;

import core.memory : GC;
import core.stdc.stdlib : exit;

import std.exception : enforce;

import data_dir : DataDir;
import ledstrip.ledstrip : Ledstrip;
import ledstrip.ledstrip_states : LedstripStates;
import mailbox : Mailbox;
import script.script_instances : ScriptInstances;
import thread_manager : ThreadManager;
import webserver.webserver : Webserver;

import vibe.core.core : disableDefaultSignalHandlers, runApplication;
import vibe.core.log;
import vibe.core.path;
import vibe.core.process : Config, execute, spawnProcess;

@safe:

// TODO:
// fix: synchronize entire rest api procedures on the objects they interact with
// fix: re-enable python now that we have threads instead of fibers
// feat: mqtt
// fix: switch to something more efficient than REST (ws graph? https://github.com/jnms-me/netsim-prototype/blob/2c93ce7/server/source/netsim/graph/graph.d#L185)
// => feat: send proper errors in api
//   => feat: show errors in frontend
//     => feat: on segment/script instance led count mismatch, render partially, but warn in frontend
// => feat: script logging, exposed via api
//   => feat: show script logs in frontend
// => feat: visualize leds in frontend
// feat: track script cpu usage, for now: htop, H, F4 ledstrip
// feat: scripting api for segments

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