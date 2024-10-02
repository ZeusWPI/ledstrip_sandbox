module main;
// dfmt off

import config : Config, ConfigSegment;
import data_dir : DataDir;
import ledstrip;
import ledstrip.led_assignments : LedAssignments, Segment;
import script.bf.bf_script : BfScript;
import script.lua.lua_script : LuaScript;
import script.script : Script;
import webserver.webserver : Webserver;

import core.sys.posix.signal : SIGHUP, SIGINT, signal, SIGTERM;
import core.time : Duration, msecs, seconds;

import std.algorithm : canFind, each, endsWith, any;
import std.exception : enforce;
import std.format : f = format;
import std.stdio : stderr, stdout;

import bindbc.rpi_ws281x.rpi_ws281x : WS2811_TARGET_FREQ, WS2812_STRIP;

import vibe.core.core : logicalProcessorCount, runEventLoopOnce, runTask;
import vibe.core.log;
import vibe.core.task : Task;
import vibe.core.taskpool : TaskPool;

@safe:

// TODO: store filename in script
// TODO: editor
// TODO: only copy segment leds that changed

final
class Main
{
    private enum uint ct_targetFreq = WS2811_TARGET_FREQ;
    private enum uint ct_ledStripType = WS2812_STRIP;

    private static typeof(this) s_instance;

    private Config m_config;
    private Duration m_frameTime;
    private LedAssignments m_ledAssignments;
    private Ledstrip m_ledstrip;
    private TaskPool m_scriptTaskPool;
    private Script[] m_scripts;
    private Task[] m_scriptTasks;
    private Webserver m_webserver;
    private bool m_doCleanup;
    private bool m_stopEventLoop;

    @disable this(ref typeof(this));

    private static
    void createInstance()
    in (s_instance is null)
    out (; s_instance !is null)
    {
        s_instance = new typeof(this);
    }

    static nothrow @nogc
    typeof(this) instance()
    in (s_instance !is null)
        => s_instance;

    private
    this()
    {
        setLogLevel(LogLevel.diagnostic);

        // setupSignalHandlers;
        loadConfig;
        createLedAssignments;
        createLedstrip;
        createScriptTaskPool;
        loadScripts;
        createWebserver;
    }

    private @trusted nothrow @nogc
    void setupSignalHandlers()
    {
        foreach(sig; [SIGHUP, SIGINT, SIGTERM])
            signal(sig, &signalHandler);
    }

    private static nothrow @nogc extern (C)
    void signalHandler(int sig)
    {
        typeof(this).instance.m_doCleanup = true;
    }

    private
    void loadConfig()
    {
        m_config = DataDir.loadConfig;
        m_frameTime = 1.seconds / m_config.fps;
    }

    private pure nothrow
    void createLedAssignments()
    {
        m_ledAssignments = new LedAssignments(m_config.ledCount);
    }

    private
    void createLedstrip()
    {
        version (LedstripWs2811)
        {
            m_ledstrip = new LedstripWs2811(
                m_ledAssignments, m_frameTime,
                ct_targetFreq, m_config.dmaNumber, m_config.gpioPin, ct_ledStripType,
            );
        }
        else
        {
            m_ledstrip = new LedstripVirtual(
                m_ledAssignments, m_frameTime,
            );
        }
    }

    private
    void createScriptTaskPool()
    {
        m_scriptTaskPool = new TaskPool(logicalProcessorCount);
    }

    private
    void loadScripts()
    {
        foreach (string state, ConfigSegment[] configSegments; m_config.states)
            foreach (ConfigSegment seg; configSegments)
            {
                string scriptString = DataDir.loadScript(seg.scriptFileName);
                loadScript(seg.scriptFileName, scriptString, state, seg.begin, seg.end);
            }
    }

    void loadScript(string scriptFileName, string scriptString, string state, uint begin, uint end, bool start = false)
    {
        Segment(begin, end).enforceIsValid(m_config.ledCount, /*ignoreSlice:*/ true);

        Script script;
        if (scriptFileName.endsWith(".bf"))
        {
            script = new BfScript(scriptFileName, scriptString, end - begin);
        }
        else if (scriptFileName.endsWith(".lua"))
        {
            script = new LuaScript(scriptFileName, scriptString, end - begin);
        }
        else
        {
            throw new Exception(f!`loadScript: Unknown script type for filename "%s"`(scriptFileName));
        }

        m_scripts ~= script;

        m_ledAssignments.assign(state, begin, end, script);

        if (start)
            startScript(script);
    }

    void startScript(Script script)
    {
        enforce(m_scripts.canFind!"a is b"(script), f!`startScript: Unknown script "%s"`(script));
        m_scriptTasks ~= script.start(m_scriptTaskPool);
    }

    void createWebserver()
    {
        m_webserver = new Webserver(m_config.httpBindAddresses, m_config.httpPort);
    }

    private
    void run()
    {
        m_ledstrip.startRenderLoopTask;
        m_scripts.each!(s => startScript(s));
        m_webserver.start;

        while (true)
        {
            runEventLoopOnce;
        }
    }

    inout(LedAssignments) ledAssignments() inout
        => m_ledAssignments;
}

void main()
{
    Main.createInstance;
    Main.instance.run;
}
