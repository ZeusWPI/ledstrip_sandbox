module ledstrip.ledstrip;
// dfmt off

import ledstrip.led : Led;
import ledstrip.ledstrip_segment : LedstripSegment;
import ledstrip.ledstrip_states : LedstripStates;
import script.script : Script;
import main : Main;

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

    synchronized
    this(LedstripStates states, Duration frameTime)
    {
        enf(states !is null);
        enf(frameTime > Duration.zero);

        m_states = states;
        m_ledCount = states.ledCount;
        m_frameTime = frameTime;
        m_stopRenderLoop = true;

        m_states.setOnActiveStateChange(&onActiveStateChange);
    }

    @disable this(ref typeof(this));

    final synchronized
    void startRenderLoopTask()
    in (m_stopRenderLoop)
    out (; !m_stopRenderLoop)
    {
        m_stopRenderLoop = false;
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
                synchronized
                {
                    foreach (begin, const LedstripSegment seg; m_states.activeState.segments)
                    {
                        const Script constScript = seg.script;
                        if (constScript.ledsChanged)
                        {
                            leds[seg.begin .. seg.end] = constScript.leds[];

                            assert(constScript.name in Main.instance.scripts);
                            Script script = Main.instance.scripts[constScript.name];
                            script.resetLedsChanged;
                        }
                    }
                }
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

    private synchronized nothrow
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
