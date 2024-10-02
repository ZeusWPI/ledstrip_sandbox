module ledstrip.ledstrip;
// dfmt off

import ledstrip.led : Led;
import ledstrip.led_assignments : LedAssignments;

import core.atomic : atomicOp;
import core.time : Duration;

import std.datetime : Clock, SysTime;
import std.exception : basicExceptionCtors;
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

class Ledstrip
{
    private const LedAssignments m_ledAssignments;
    private const size_t m_ledCount;
    private Duration m_frameTime;
    private bool m_stopRenderLoop;

    this(LedAssignments ledAssignments, Duration frameTime)
    in (ledAssignments !is null)
    in (ledAssignments.ledCount > 0)
    in (frameTime > Duration.zero)
    {
        m_ledAssignments = ledAssignments;
        m_ledCount = ledAssignments.ledCount;
        m_frameTime = frameTime;
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
                foreach (seg; ledAssignments.currSegments)
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

    protected abstract
    void render();

    final pure nothrow @nogc
    size_t ledCount() const
        => m_ledCount;

    final pure nothrow @nogc
    const(LedAssignments) ledAssignments() const
        => m_ledAssignments;

    final nothrow @nogc
    ulong frameCount() const
        => g_frameCount;

    final pure nothrow @nogc
    void stopRenderLoop()
    {
        m_stopRenderLoop = true;
    }

    abstract pure nothrow @nogc
    Led[] leds();
}

class LedStripException : Exception
{
    mixin basicExceptionCtors;
}
