module ledstrip.ledstrip;

import data_dir : DataDir;
import ledstrip.led : Led;
import ledstrip.ledstrip_segment : LedstripSegment;
import ledstrip.ledstrip_state : LedstripState;
import ledstrip.ledstrip_states : LedstripStates;
import script.script_instance : ScriptInstance;
import script.script_instances : ScriptInstances;
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

    private alias enf = enforce!LedstripException;
    private enum uint ct_framesBetweenWarns = 10;

    private const uint m_ledCount;
    private bool m_stopRenderLoop;
    private bool m_fullRefresh;
    private uint m_framesSinceTimeWarn;
    private ulong m_frameCount;

    protected synchronized
    this()
    {
        m_ledCount = DataDir.sharedConfig.ledCount;
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
                    + DataDir.sharedConfig.frameTime;
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
        ubyte maxBrightness = DataDir.sharedConfig.maxBrightness;
        if (m_fullRefresh)
            leds[] = Led(0, 0, 0);
        synchronized (ScriptInstances.classinfo)
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
                    if (scriptInstance.ledCount == seg.end - seg.begin)
                    {
                        foreach (i; 0 .. scriptInstance.ledCount)
                        {
                            shared(Led) led = scriptInstance.leds[i];
                            led = led.limitBrightness(maxBrightness);
                            leds[seg.begin + i] = led;
                        }
                    }
                    else
                    {
                        logWarn(
                            `copySegmentLeds: Segment in state "%s" with begin "%u" and led count "%u"`
                                ~ ` doesn't match the led count "%u" of script instance "%s"`,
                            activeState.name, begin, seg.ledCount, scriptInstance.ledCount, scriptInstance.name,
                        );
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
        => m_frameCount;

    final pure nothrow @nogc
    void stopRenderLoop()
    {
        m_stopRenderLoop = true;
    }

    final pure nothrow @nogc
    void fullRefresh()
    {
        m_fullRefresh = true;
    }

    private synchronized nothrow @nogc
    void onActiveStateChange()
    {
        fullRefresh;
    }

    protected abstract
    void render()
    in (ThreadManager.constInstance.inMainThread, "Ledstrip: render must be called from main thread");

    abstract nothrow @nogc
    shared(Led)[] leds();
}

class LedstripException : Exception
{
    mixin basicExceptionCtors;
}
