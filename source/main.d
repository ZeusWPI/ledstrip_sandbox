module main;

import config : Config, ConfigScript, ConfigSegment, ConfigState;
import data_dir : DataDir;
import ledstrip;
import ledstrip.ledstrip_state : LedstripState;
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

// TODO: editor
// TODO: scripting api for segments

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
    private Script[string] m_scripts;
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

    static nothrow @nogc
    const(Main) constInstance()
    in (s_instance !is null)
        => s_instance;

    private
    this()
    {
        setLogLevel(LogLevel.diagnostic);
        setLogFormat(FileLogger.Format.thread, FileLogger.Format.thread);

        // setupSignalHandlers;
        loadConfig;
        createLedstripStates;
        createLedstrip;
        createScriptTaskPool;
        createConfigScripts;
        createConfigStates;
        m_states.setDefaultActive;
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
        m_scriptTaskPool = new TaskPool(logicalProcessorCount, "scriptTaskPool");
    }

    private
    void createConfigScripts()
    {
        foreach (configScriptName, configScript; m_config.scripts)
        {
            string sourceCode = DataDir.loadScript(configScript.fileName);

            Script script;
            if (configScript.fileName.endsWith(".bf"))
            {
                script = new BfScript(
                    configScriptName, configScript.fileName, sourceCode, configScript.ledCount,
                );
            }
            else if (configScript.fileName.endsWith(".lua"))
            {
                script = new LuaScript(
                    configScriptName, configScript.fileName, sourceCode, configScript.ledCount,
                );
            }
            else
            {
                string msg = f!`loadScript: Unknown script type for filename "%s"`(
                    configScript.fileName,
                );
                throw new Exception(msg);
            }
            m_scripts[configScriptName] = script;
        }
    }

    private
    void createConfigStates()
    {
        foreach (stateName, configState; m_config.states)
        {
            LedstripState state = m_states.addState(stateName);
            foreach (configSegment; configState.segments)
            {
                enforce(
                    configSegment.scriptName in m_scripts,
                    f!"createConfigStates: no such script %s"(configSegment.scriptName),
                );
                Script script = m_scripts[configSegment.scriptName];
                state.assignSegment(configSegment.begin, configSegment.end, script);
            }
        }
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
    in (script !is null, "startScript: script is null")
    {
        enforce(script.name in m_scripts, f!`startScript: Unknown script "%s"`(script.name));
        enforce(script is m_scripts[script.name], f!`startScript: Unknown script "%s"`(script.name));
        m_scriptTasks ~= script.start(m_scriptTaskPool);
    }

    pure nothrow @nogc
    Duration frameTime() const
        => m_frameTime;

    pure nothrow @nogc
    inout(LedstripStates) states() inout
        => m_states;

    pure nothrow @nogc
    inout(shared(Script[string])) scripts() inout
        => m_scripts;
}

void main()
{
    Main.createInstance;
    Main.instance.run;
}
