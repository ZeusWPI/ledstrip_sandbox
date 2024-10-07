module main;

import data_dir : DataDir;
import ledstrip.ledstrip_states : LedstripStates;
import ledstrip.ledstrip : Ledstrip;
import script.scripts : Scripts;
import thread_manager : ThreadManager;
import webserver.webserver : Webserver;

import vibe.core.core : runEventLoopOnce;
import vibe.core.log;

@safe:

// TODO: lua auto yield
// TODO: editor
// TODO: scripting api for segments

void main()
{
    setLogLevel(LogLevel.diagnostic);
    setLogFormat(FileLogger.Format.thread, FileLogger.Format.thread);

    // These have no dependencies
    DataDir.createInstance;
    ThreadManager.createInstance;

    // These depend on DataDir and/or ThreadManager
    Scripts.createInstance;
    LedstripStates.createInstance; // Depends on Scripts
    Ledstrip.createInstance;
    Webserver.createInstance;

    Ledstrip.instance.startRenderLoopTask;
    Scripts.instance.startAutoStartTask;
    Webserver.instance.start;

    while (true)
    {
        runEventLoopOnce;
    }
}
