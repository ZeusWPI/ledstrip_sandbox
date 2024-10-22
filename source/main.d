module main;

import data_dir : DataDir;
import ledstrip.ledstrip : Ledstrip;
import ledstrip.ledstrip_states : LedstripStates;
import script.scripts : Scripts;
import thread_manager : ThreadManager;
import webserver.webserver : Webserver;

import vibe.core.core : runEventLoopOnce;
import vibe.core.path;
import vibe.core.log;
import vibe.core.process : spawnProcess, Config, execute;

@safe:

// TODO: show errors in frontend
// TODO: improve script logging
// TODO: track script cpu usage
// TODO: improve mailbox
// TODO: synchronize rest api procedures with collection singletons
// TODO: scripting api for segments

void main()
{
    setLogLevel(LogLevel.diagnostic);
    setLogFormat(FileLogger.Format.thread, FileLogger.Format.thread);

    // These have no dependencies
    ThreadManager.createInstance;

    // These depend on ThreadManager
    DataDir.createInstance;

    // These depend on DataDir and/or ThreadManager
    Scripts.createInstance;
    LedstripStates.createInstance;
    Ledstrip.createInstance;
    Webserver.createInstance;

    Ledstrip.instance.startRenderLoopTask;
    Scripts.instance.startAutoStartTask;
    Webserver.instance.start;

    spawnProcess(["node", "luals/ws-wrapper.js"]);
    
    while (true)
    {
        runEventLoopOnce;
    }
}
