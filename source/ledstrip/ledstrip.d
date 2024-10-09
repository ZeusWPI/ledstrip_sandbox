module ledstrip.ledstrip;

import data_dir : DataDir;
import ledstrip.led : Led;
import ledstrip.ledstrip_segment : LedstripSegment;
import ledstrip.ledstrip_states : LedstripStates;
import ledstrip.ledstrip_state : LedstripState;
import script.script : Script;
import script.scripts : Scripts;
import singleton : sharedSingleton;
import thread_manager : ThreadManager;

import core.atomic : atomicOp;
import core.time : Duration;

import std.datetime : Clock, SysTime;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import std.stdio : stderr, stdout, write, writef, writefln, writeln;
import std.traits : isInstanceOf;

import vibe.core.core : runTask, sleep, yield;
import vibe.core.log;

@safe:

abstract shared
class Ledstrip
{
    mixin sharedSingleton!( /*customCreateInstance:*/ true);

    static
    void createInstance()
    {
        // TODO: read type from config
        version (LedstripWs2811)
        {
            import ledstrip.ledstrip_ws2811 : LedstripWs2811;

            s_instance = new LedstripWs2811;
        }
        else
        {
            import ledstrip.ledstrip_virtual : LedstripVirtual;

            s_instance = new LedstripVirtual;
        }
    }

    private alias enf = enforce!LedStripException;
    private enum uint ct_framesBetweenWarns = 10;

    private const uint m_ledCount;
    private bool m_stopRenderLoop;
    private uint m_framesSinceTimeWarn;
    private ulong m_frameCount;

    protected synchronized
    this()
    {
        m_ledCount = DataDir.constInstance.config.ledCount;
        m_stopRenderLoop = true;
        m_framesSinceTimeWarn = uint.max;

        LedstripStates.instance.setOnActiveStateChange(&onActiveStateChange);
    }

    @disable this(ref typeof(this));

    final synchronized
    void startRenderLoopTask()
    in (ThreadManager.constInstance.inMainThread, "Ledstrip: startRenderLoopTask must be called from main thread")
    in (m_stopRenderLoop)
    out (; !m_stopRenderLoop)
    {
        m_stopRenderLoop = false;
        runTask(&renderLoop);
    }

    private nothrow
    void renderLoop()
    in (ThreadManager.constInstance.inMainThread, "Ledstrip: renderLoop must be called from main thread")
    {
        try
        {
            while (!m_stopRenderLoop)
            {
                SysTime entryTime = Clock.currTime;
                copySegmentLeds;
                render();
                m_frameCount.atomicOp!"+="(1);

                if (m_framesSinceTimeWarn < ct_framesBetweenWarns)
                    m_framesSinceTimeWarn.atomicOp!"+="(1);

                Duration timeToSleep = entryTime - Clock.currTime
                    + DataDir.constInstance.config.frameTime;
                if (timeToSleep.isNegative)
                {
                    if (m_framesSinceTimeWarn >= ct_framesBetweenWarns)
                    {
                        logWarn("Passed frame time before sleeping. Consider lowering fps.");
                        m_framesSinceTimeWarn = 0;
                    }
                    yield;
                }
                else
                {
                    sleep(timeToSleep);
                }
            }
        }
        catch (Exception e)
        {
            logError("Exception in render loop: %s", (() @trusted => e.toString)());
        }
    }

    private synchronized
    void copySegmentLeds()
    {
        synchronized (Scripts.classinfo)
        {
            Script[string] changedScripts;
            foreach (string name, Script script; Scripts.instance.scripts)
                if (script.ledsChanged)
                {
                    script.resetLedsChanged;
                    changedScripts[name] = script;
                }
            const LedstripState activeState = LedstripStates.constInstance.activeState;
            foreach (uint begin, const LedstripSegment seg; activeState.segments)
            {
                if (seg.scriptName in changedScripts)
                {
                    const Script script = changedScripts[seg.scriptName];
                    if (script.ledCount == seg.end - seg.begin)
                        leds[seg.begin .. seg.end] = script.leds[];
                    else
                    {
                        logWarn(
                            `copySegmentLeds: Segment in state "%s" with begin "%u" and led count "%u"`
                                ~ ` doesn't match the led count "%u" of script "%s"`,
                            activeState.name, begin, seg.ledCount, script.ledCount, script.name,
                        );
                    }
                }
            }
        }
    }

    final pure nothrow @nogc
    uint ledCount() const
        => m_ledCount;

    final pure nothrow @nogc
    ulong frameCount() const
        => m_frameCount;

    final pure nothrow @nogc
    void stopRenderLoop()
    {
        m_stopRenderLoop = true;
    }

    private synchronized nothrow @nogc
    void onActiveStateChange()
    {
        leds[] = Led(0, 0, 0);
    }

    protected abstract
    void render()
    in (ThreadManager.constInstance.inMainThread, "Ledstrip: render must be called from main thread");

    abstract nothrow @nogc
    shared(Led)[] leds();
}

class LedStripException : Exception
{
    mixin basicExceptionCtors;
}
