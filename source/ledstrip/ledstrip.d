module ledstrip.ledstrip;
// dfmt off

import ledstrip.led : Led;
import ledstrip.ledstrip_states : LedstripStates;

import core.atomic : atomicOp;
import core.time : Duration;

import std.datetime : Clock, SysTime;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import std.stdio : stderr, stdout, write, writef, writefln, writeln;
import std.traits : isInstanceOf;

import vibe.core.core : runTask, sleep;
import vibe.core.log;

@safe:

private static shared ulong g_frameCount;

nothrow @nogc
ulong frameCount()
    => g_frameCount;

shared
class Ledstrip
{
    alias enf = enforce!LedStripException;

    private LedstripStates m_states;
    private const uint m_ledCount;
    private Duration m_frameTime;
    private bool m_stopRenderLoop;

    this(LedstripStates states, Duration frameTime)
    {
        enf(states !is null);
        enf(frameTime > Duration.zero);

        m_states = states;
        m_ledCount = states.ledCount;
        m_frameTime = frameTime;

        m_states.setOnActiveStateChange(&onActiveStateChange);
    }

    @disable this(ref typeof(this));

    final
    void startRenderLoopTask()
    {
        runTask(&renderLoop);
    }

    private nothrow
    void renderLoop()
    {
        try
        {
            while (!m_stopRenderLoop)
            {
                SysTime entryTime = Clock.currTime;
                foreach (seg; m_states.activeState.segments)
                    leds[seg.begin .. seg.end] = seg.script.leds[];
                render();
                g_frameCount.atomicOp!"+="(1);

                Duration timeToSleep = entryTime - Clock.currTime + m_frameTime;
                if (timeToSleep.isNegative)
                    logWarn("Passed frame time before sleeping. Consider lowering fps.");
                else
                    sleep(timeToSleep);
            }
        }
        catch (Exception e)
        {
            logError("Exception in render loop: %s", (() @trusted => e.toString)());
        }
    }

    final pure nothrow @nogc
    uint ledCount() const
        => m_ledCount;

    final pure nothrow @nogc
    const(LedstripStates) states() const
        => m_states;

    final nothrow @nogc
    ulong frameCount() const
        => g_frameCount;

    final pure nothrow @nogc
    void stopRenderLoop()
    {
        m_stopRenderLoop = true;
    }

    private nothrow
    void onActiveStateChange()
    {
        leds[] = Led(0, 0, 0);
    }

    protected abstract
    void render();

    abstract nothrow @nogc
    shared(Led)[] leds();
}

class LedStripException : Exception
{
    mixin basicExceptionCtors;
}
