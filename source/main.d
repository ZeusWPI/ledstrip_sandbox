module main;

import data_dir : DataDir;
import ledstrip.ledstrip : Ledstrip;
import ledstrip.ledstrip_states : LedstripStates;
import mailbox : Mailbox;
import script.scripts : Scripts;
import thread_manager : ThreadManager;
import webserver.webserver : Webserver;

import vibe.core.core : runEventLoopOnce;
import vibe.core.log;
import vibe.core.path;
import vibe.core.process : Config, execute, spawnProcess;

@safe:

// TODO: show errors in frontend
// TODO: improve script logging
// TODO: track script cpu usage
// TODO: synchronize rest api procedures with collection singletons
// TODO: scripting api for segments
// TODO: switch to something more efficient than REST
// TODO: visualize leds in frontend
// TODO: python auto yield
// TODO: improve autoStartTask
// TODO: improve in...TaskPool

void main()
{
    setLogLevel(LogLevel.diagnostic);
    setLogFormat(FileLogger.Format.thread, FileLogger.Format.thread);

    // These have no dependencies
    ThreadManager.createInstance;
    Mailbox.createInstance;

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

    // spawnProcess(["node", "luals/ws-wrapper.js"]);
    
    while (true)
    {
        runEventLoopOnce;
    }
}
