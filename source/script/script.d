module script.script;

import ledstrip.led : Led;

import core.atomic;
import core.time : Duration, seconds;

import std.algorithm : any, canFind, endsWith;
import std.datetime : Clock, SysTime;
import std.exception : enforce;

import vibe.core.log;
import vibe.core.task : Task;
import vibe.core.taskpool : TaskPool;

@safe:

abstract shared
class Script
{
    private long m_lastStartTime;

    private string m_name;
    private string m_fileName;
    private string m_sourceCode;
    private Led[] m_leds;
    private bool m_running;

    @disable this(ref typeof(this));

    protected
    this(string name, string fileName, string sourceCode, uint ledCount)
    {
        enforce(name.length);
        enforce(fileName.isValidScriptFileName);
        enforce(ledCount > 0);

        m_name = name;
        m_fileName = fileName;
        m_sourceCode = sourceCode;
        m_leds = new Led[ledCount];

        reset;
    }

    final pure nothrow @nogc
    string name() const
        => m_name;

    final pure nothrow @nogc
    string fileName() const
        => m_fileName;

    final pure nothrow @nogc
    string sourceCode() const
        => m_sourceCode;

    final pure nothrow @nogc
    bool running() const
        => m_running;

    final pure nothrow @nogc
    inout(shared(Led[])) leds() inout
        => m_leds;
    
    Task start(TaskPool taskPool)
    {
        m_running = false;
        m_lastStartTime = Clock.currTime.stdTime;
        return Task.init;
    }

    nothrow
    void reset()
    {
        m_running = false;
        m_lastStartTime = 0;
    }

    abstract nothrow
    Duration runtimeSinceLastPause();

    final nothrow
    double averageCpuUsageSinceLastPause()
    {
        if (running)
        {
            try
                return (runtimeSinceLastPause / (Clock.currTime.stdTime - m_lastStartTime)) / 1
                    .seconds;
            catch (Exception e)
                logError("Failed to get average cpu usage: %s", (() @trusted => e.toString)());
        }
        return 0.0;
    }
}

bool isValidScriptFileName(string name)
{
    if (name.canFind("/"))
        return false;

    if (![".lua", ".bf"].any!(ext => name.endsWith(ext)))
        return false;

    return true;
}
