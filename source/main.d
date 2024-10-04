module main;
// dfmt off

import config : Config, ConfigSegment;
import data_dir : DataDir;
import ledstrip;
import ledstrip.ledstrip_states : LedstripStates;
import script.bf.bf_script : BfScript;
import script.lua.lua_script : LuaScript;
import script.script : Script;
import webserver.webserver : Webserver;

import core.sys.posix.signal : SIGHUP, SIGINT, signal, SIGTERM;
import core.time : Duration, msecs, seconds;

import std.algorithm : any, canFind, each, endsWith;
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

final shared
class Main
{
    private enum uint ct_targetFreq = WS2811_TARGET_FREQ;
    private enum uint ct_ledStripType = WS2812_STRIP;

    private static typeof(this) s_instance;

    private Config m_config;
    private Duration m_frameTime;
    private LedstripStates m_states;
    private Ledstrip m_ledstrip;
    private TaskPool m_scriptTaskPool;
    private Script[] m_scripts;
    private Task[] m_scriptTasks;
    private __gshared Webserver m_webserver;

    @disable this(ref typeof(this));

    private static
    void createInstance()
    in (s_instance is null)
    out (; s_instance !is null)
    {
        s_instance = new typeof(this);
    }

    static nothrow @nogc
    Main instance()
    in (s_instance !is null)
        => s_instance;

    private
    this()
    {
        setLogLevel(LogLevel.diagnostic);

        // setupSignalHandlers;
        loadConfig;
        createLedstripStates;
        createLedstrip;
        createScriptTaskPool;
        loadConfigSegments;
        m_states.setActiveState("default");
        createWebserver;
    }

    private
    void loadConfig()
    {
        m_config = (() @trusted => cast(shared) DataDir.loadConfig)();
        m_frameTime = 1.seconds / m_config.fps;
    }

    private pure
    void createLedstripStates()
    {
        m_states = new LedstripStates(m_config.ledCount);
    }

    private
    void createLedstrip()
    {
        version (LedstripWs2811)
        {
            m_ledstrip = new LedstripWs2811(
                m_states, m_frameTime,
                ct_targetFreq, m_config.dmaNumber, m_config.gpioPin, ct_ledStripType,
            );
        }
        else
        {
            m_ledstrip = new LedstripVirtual(
                m_states, m_frameTime,
            );
        }
    }

    private
    void createScriptTaskPool()
    {
        m_scriptTaskPool = new TaskPool(logicalProcessorCount);
    }

    private
    void loadConfigSegments()
    {
        foreach (string state, shared(ConfigSegment[]) configSegments; m_config.states)
            foreach (ConfigSegment seg; configSegments)
            {
                try
                {
                    loadConfigSegment(state, seg.scriptFileName, seg.begin, seg.end);
                }
                catch (Exception e)
                {
                    logError(
                        "Failed to load config segment %s: %s",
                        seg, (() @trusted => e.toString)(),
                    );
                }
            }
    }

    private
    void loadConfigSegment(string state, string scriptFileName, uint begin, uint end)
    {
        string scriptString = DataDir.loadScript(scriptFileName);

        Script script;
        if (scriptFileName.endsWith(".bf"))
            script = new BfScript(state, scriptFileName, scriptString, end - begin);
        else if (scriptFileName.endsWith(".lua"))
            script = new LuaScript(state, scriptFileName, scriptString, end - begin);
        else
            throw new Exception(f!`loadScript: Unknown script type for filename "%s"`(scriptFileName));

        if (state !in m_states.states)
            m_states.addState(state);
        
        m_states.states[state].assignSegment(begin, end, script);

        m_scripts ~= script;
    }

    private @trusted
    void createWebserver()
    {
        m_webserver = new Webserver(cast(string[]) m_config.httpBindAddresses, m_config.httpPort);
    }

    private
    void run()
    {
        m_ledstrip.startRenderLoopTask;
        m_scripts.each!(s => startScript(s));
        (() @trusted => m_webserver.start)();

        while (true)
        {
            runEventLoopOnce;
        }
    }

    private
    void startScript(Script script)
    {
        enforce(m_scripts.canFind!"a is b"(script), f!`startScript: Unknown script "%s"`(script));
        m_scriptTasks ~= script.start(m_scriptTaskPool);
    }

    pure nothrow @nogc
    inout(LedstripStates) states() inout
        => m_states;
}

void main()
{
    Main.createInstance;
    Main.instance.run;
}
