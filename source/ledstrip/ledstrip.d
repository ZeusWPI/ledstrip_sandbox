module ledstrip.ledstrip;

import data_dir : DataDir;
import ledstrip.led : Led;
import ledstrip.ledstrip_segment : LedstripSegment;
import ledstrip.ledstrip_state : LedstripState;
import ledstrip.ledstrip_states : LedstripStates;
import script.script_instance : ScriptInstance;
import script.script_instances : ScriptInstances;
import singleton : sharedSingleton;
import thread_manager : inThreadKind, ThreadKind;

import core.atomic : atomicLoad, atomicOp, atomicStore;
import core.thread : Thread;
import core.time : Duration;

import std.datetime : Clock, SysTime;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import std.stdio : stderr, stdout, write, writef, writefln, writeln;
import std.traits : isInstanceOf;

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

    private alias enf = enforce!LedstripException;
    private enum uint ct_framesBetweenWarns = 10;

    private const uint m_ledCount;
    private bool m_stopRenderLoop;
    private bool m_fullRefresh;
    private uint m_framesSinceTimeWarn;
    private ulong m_frameCount;

    protected synchronized
    this()
    in (inThreadKind(ThreadKind.main))
    {
        m_ledCount = DataDir.sharedConfig.ledCount;
        m_stopRenderLoop = true;
        m_framesSinceTimeWarn = uint.max;
    }

    @disable this(ref typeof(this));

    nothrow @trusted //
     ~this()
    in (inThreadKind(ThreadKind.main))
    {
    }

    final nothrow synchronized
    void renderLoop()
    in (inThreadKind(ThreadKind.renderer))
    {
        m_stopRenderLoop = false;
        while (!m_stopRenderLoop)
        {
            try
            {
                SysTime entryTime = Clock.currTime;
                copySegmentLeds;
                render();
                m_frameCount.atomicOp!"+="(1);

                if (m_framesSinceTimeWarn < ct_framesBetweenWarns)
                    m_framesSinceTimeWarn.atomicOp!"+="(1);

                Duration timeToSleep = entryTime - Clock.currTime
                    + DataDir.sharedConfig.frameTime;
                if (timeToSleep.isNegative)
                {
                    if (m_framesSinceTimeWarn >= ct_framesBetweenWarns)
                    {
                        logWarn("Passed frame time before sleeping. Consider lowering fps.");
                        m_framesSinceTimeWarn = 0;
                    }
                }
                else
                {
                    (() @trusted => Thread.sleep(timeToSleep))();
                }
            }
            catch (Exception e)
            {
                logError("Exception in render loop: %s", (() @trusted => e.toString)());
            }
        }
    }

    private synchronized
    void copySegmentLeds()
    in (inThreadKind(ThreadKind.renderer))
    {
        ubyte maxBrightness = DataDir.sharedConfig.maxBrightness;
        if (m_fullRefresh)
            leds[] = Led(0, 0, 0);
        synchronized (ScriptInstances.instance)
        {
            ScriptInstance[string] changedScriptInstances;
            auto scriptInstances = ScriptInstances.instance.scriptInstances;
            foreach (string name, ScriptInstance scriptInstance; scriptInstances)
                if (scriptInstance.ledsChanged || m_fullRefresh)
                {
                    scriptInstance.resetLedsChanged;
                    changedScriptInstances[name] = scriptInstance;
                }
            const LedstripState activeState = LedstripStates.constInstance.activeState;
            foreach (uint begin, const LedstripSegment seg; activeState.segments)
            {
                if (seg.scriptInstanceName in changedScriptInstances)
                {
                    const ScriptInstance scriptInstance
                        = changedScriptInstances[seg.scriptInstanceName];
                    size_t scriptIdx = scriptInstance.ledsShift;
                    foreach (size_t physIdx; seg.begin .. seg.end)
                    {
                        if (++scriptIdx >= scriptInstance.ledCount)
                            scriptIdx = 0; // Wrap around
                        shared(Led) led = scriptInstance.leds[scriptIdx];
                        led = led.limitBrightness(maxBrightness);
                        leds[physIdx] = led;
                    }
                }
            }
        }
        if (m_fullRefresh)
            m_fullRefresh = false;
    }

    final pure nothrow @nogc
    uint ledCount() const
        => m_ledCount;

    final pure nothrow @nogc
    ulong frameCount() const
        => m_frameCount.atomicLoad;

    final pure nothrow @nogc
    void stopRenderLoop()
    {
        m_stopRenderLoop.atomicStore(true);
    }

    final pure nothrow @nogc
    void fullRefresh()
    {
        m_fullRefresh.atomicStore(true);
    }

    protected abstract synchronized
    void render()
    in (inThreadKind(ThreadKind.renderer));

    abstract synchronized nothrow @nogc
    shared(Led)[] leds();
}

class LedstripException : Exception
{
    mixin basicExceptionCtors;
}
