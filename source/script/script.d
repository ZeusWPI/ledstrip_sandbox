module script.script;

import ledstrip.led : Led;

import core.atomic;
import core.time : Duration, seconds;

import std.datetime : Clock, SysTime;

import vibe.core.core : Task;
import vibe.core.log;

@safe:

abstract shared
class Script
{
    private long m_lastStartTime;

    protected string m_scriptString;
    protected Led[] m_leds;
    protected bool m_running;
    
    @disable this(ref typeof(this));

    protected
    this(string scriptString, size_t ledCount)
    {
        m_scriptString = scriptString;
        m_leds = new Led[ledCount];
        reset;
    }

    final pure nothrow @nogc
    bool running() const
        => m_running;

    final pure nothrow @nogc
    string scriptString() const
        => m_scriptString;

    final pure nothrow @nogc
    shared(Led[]) leds()
        => m_leds;

    Task start()
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
                return (runtimeSinceLastPause / (Clock.currTime.stdTime - m_lastStartTime)) / 1.seconds;
            catch (Exception e)
                logError("Failed to get average cpu usage: %s", (() @trusted => e.toString)());
        }
        return 0.0;
    }
}
