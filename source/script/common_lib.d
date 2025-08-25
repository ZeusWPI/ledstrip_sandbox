module script.common_lib;

import ledstrip.led : Led;
import ledstrip.ledstrip : Ledstrip;
import ledstrip.ledstrip_segment : LedstripSegment;
import ledstrip.ledstrip_states : LedstripStates;
import script.script_instance : ScriptInstance;
import script.script_instance_thread : ScriptInstanceThread;
import util : sleepFrameFraction;

import core.time : msecs;

import std.datetime : Clock;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;

import vibe.core.core : sleep;

@safe:

class CommonLib
{
    private alias enf = enforce!CommonLibException;

    @disable this();
    @disable this(ref typeof(this));

static:
    private
    ScriptInstanceThread thread()
        => ScriptInstanceThread.instance;

    private
    const(ScriptInstanceThread) constThread()
        => ScriptInstanceThread.constInstance;

    private
    ScriptInstance scriptInstance()
        => thread.scriptInstance;

    private
    const(ScriptInstance) constScriptInstance()
        => constThread.constScriptInstance;

    private
    void enfContext(bool value, string msg)
    {
        enf(value, f!`Script instance "%s": %s`(constScriptInstance.name, msg));
    }

    private
    void enfContext(bool value, string method, string msg)
    {
        enf(value, f!`Script "%s": %s: %s`(constScriptInstance.name, method, msg));
    }

    class LedModule
    {
        @disable this();
        @disable this(ref typeof(this));

    static:
        private
        shared(Led[]) leds()
            => scriptInstance.leds;

        private
        const(shared(Led[])) constLeds()
            => leds;

        private
        void setLedsChanged()
            => scriptInstance.setLedsChanged;

        uint count()
            => cast(uint) constLeds.length;

        void set(uint index, ubyte r, ubyte g, ubyte b)
        {
            enfContext(
                index < constLeds.length,
                "led.set",
                f!`Led index %u out of bounds for segment with length %u`(index, constLeds.length),
            );
            leds[index] = Led(r, g, b);
            setLedsChanged;
        }

        void setSlice(uint begin, uint end, ubyte r, ubyte g, ubyte b)
        {
            enfContext(
                begin <= end,
                "led.setSlice",
                f!`Begin index %u larger than end index %u`(begin, end),
            );
            enfContext(
                end <= constLeds.length,
                "led.setSlice",
                f!`End index %u out of bounds for segment with length %u"`(end, constLeds.length),
            );
            leds[begin .. end] = Led(r, g, b);
            setLedsChanged;
        }

        void setAll(ubyte r, ubyte g, ubyte b)
        {
            leds[] = Led(r, g, b);
            setLedsChanged;
        }
    }

    class StateModule
    {
        @disable this();
        @disable this(ref typeof(this));

    static:
        string activeName()
            => LedstripStates.constInstance.activeState.name;

        bool activeContainsThisScriptInstance()
        {
            const ScriptInstance thisScriptInstance = scriptInstance;
            auto segments = LedstripStates.constInstance.activeState.segments;
            foreach (begin, const LedstripSegment seg; segments)
                if (seg.scriptInstanceName == thisScriptInstance.name)
                    return true;
            return false;
        }

        void setActiveByName(string stateName)
        {
            LedstripStates.instance.setActiveState(stateName);
        }

        void setDefaultActive()
        {
            LedstripStates.instance.setDefaultActive;
        }
    }

    class TimeModule
    {
        @disable this();
        @disable this(ref typeof(this));

    static:
        long stdTimeHnsecs()
            => Clock.currStdTime;

        long unixTimeSeconds()
            => Clock.currTime.toUnixTime;

        void sleepMsecs(long msecs)
        {
            enfContext(
                msecs >= 0,
                "time.sleepMsecs",
                f!`Cannot sleep for less than %d msecs`(msecs),
            );
            sleep(msecs.msecs);
        }

        /// waitFrames(0) just returns, waitFrames(1) waits until the next render...
        void waitFrames(ulong frames)
        {
            ulong frameCountAtEntry = Ledstrip.constInstance.frameCount;
            while (Ledstrip.constInstance.frameCount < frameCountAtEntry + frames)
                sleepFrameFraction(5);
        }
    }

    class MailboxModule
    {
        @disable this();
        @disable this(ref typeof(this));

    static:
        void subscribe(string topic)
        {
            thread.mailboxSubscribe(topic);
        }

        void unsubscribe(string topic)
        {
            thread.mailboxUnsubscribe(topic);
        }

        void unsubscribeAll()
        {
            thread.mailboxUnsubscribeAll();
        }

        string consume(string topic)
            => thread.mailboxConsume(topic);
    }
}

class CommonLibException : Exception
{
    mixin basicExceptionCtors;
}
