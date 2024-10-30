module script.common_lib;

import ledstrip.led : Led;
import ledstrip.ledstrip : Ledstrip;
import ledstrip.ledstrip_segment : LedstripSegment;
import ledstrip.ledstrip_states : LedstripStates;
import script.script : Script;
import script.script_task : ScriptTask;
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
    ScriptTask task()
        => ScriptTask.instance;

    private
    const(ScriptTask) constTask()
        => ScriptTask.constInstance;

    private
    Script script()
        => task.script;

    private
    const(Script) constScript()
        => constTask.constScript;

    private
    void enfContext(bool value, string msg)
    {
        enf(value, f!`Script "%s": %s`(constScript.name, msg));
    }

    private
    void enfContext(bool value, string method, string msg)
    {
        enf(value, f!`Script "%s": %s: %s`(constScript.name, method, msg));
    }

    class LedModule
    {
        @disable this();
        @disable this(ref typeof(this));

    static:
        private
        shared(Led[]) leds()
            => script.leds;

        private
        const(shared(Led[])) constLeds()
            => leds;

        private
        void setLedsChanged()
            => script.setLedsChanged;

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

        bool activeContainsThisScript()
        {
            const Script thisScript = script;
            auto segments = LedstripStates.constInstance.activeState.segments;
            foreach (begin, const LedstripSegment seg; segments)
                if (seg.scriptName == thisScript.name)
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
            task.mailboxSubscribe(topic);
        }

        void unsubscribe(string topic)
        {
            task.mailboxUnsubscribe(topic);
        }

        void unsubscribeAll()
        {
            task.mailboxUnsubscribeAll();
        }

        string consume(string topic)
            => task.mailboxConsume(topic);
    }
}

class CommonLibException : Exception
{
    mixin basicExceptionCtors;
}
