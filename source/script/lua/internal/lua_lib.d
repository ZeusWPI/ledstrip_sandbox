module script.lua.internal.lua_lib;

import ledstrip.led : Led;
import ledstrip.ledstrip : frameCount;
import ledstrip.ledstrip_segment : LedstripSegment;
import main : Main;
import script.lua.internal.lua_script_task : LuaScriptTask;
import script.lua.lua_script : LuaScript;
import script.script : Script;
import webserver.mailbox : Mailbox;

import core.time : msecs;

import std.conv : text;
import std.datetime : Clock;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import std.string : toStringz;
import std.traits : EnumMembers;

import vibe.core.core : sleep;
import vibe.core.log;

import bindbc.lua.v51 : lua_getglobal;

import lumars : LuaFunc, LuaNil, LuaTable, LuaValue, LuaVariadic;

@safe:

class LuaLib
{
    @disable this();
    @disable this(ref typeof(this));

static:
    nothrow @trusted
    LuaTable buildEnv(LuaScriptTask scriptTask)
    {
        LuaTable createTable()
        {
            return LuaTable.makeNew(&scriptTask.luaState());
        }

        T getGlobal(T)(string key)
        {
            lua_getglobal(scriptTask.luaState.handle, key.toStringz);
            scope (exit)
                scriptTask.luaState.pop(1);
            return scriptTask.luaState.get!T(scriptTask.luaState.top);
        }

        void addGlobalToTable(T = LuaFunc)(LuaTable t, string k) => t[k] = getGlobal!T(k);

        try
        {
            LuaTable env = createTable;

            // Values
            addGlobalToTable!LuaValue(env, "_VERSION");

            // Core
            addGlobalToTable(env, "type");

            // Error handling
            addGlobalToTable(env, "assert");
            addGlobalToTable(env, "error");
            addGlobalToTable(env, "pcall");
            addGlobalToTable(env, "xpcall");

            // String ops
            addGlobalToTable(env, "tonumber");
            addGlobalToTable(env, "tostring");
            addGlobalToTable(env, "unpack");
            addGlobalToTable!LuaTable(env, "string"); // Module

            // Table ops
            addGlobalToTable(env, "next");
            addGlobalToTable(env, "pairs");
            addGlobalToTable(env, "ipairs");
            addGlobalToTable(env, "select");
            addGlobalToTable!LuaTable(env, "table");

            // Other modules
            addGlobalToTable!LuaTable(env, "bit");
            addGlobalToTable!LuaTable(env, "math");

            // Custom
            env["log"] = &log;
            env["led"] = () {
                LuaTable led = createTable;
                led["count"] = LedModule.count; // Value
                led["set"] = &LedModule.set;
                led["setSlice"] = &LedModule.setSlice;
                led["setAll"] = &LedModule.setAll;
                return led;
            }();
            env["state"] = () {
                LuaTable state = createTable;
                state["activeName"] = &StateModule.activeName;
                state["activeContainsThisScript"] = &StateModule.activeContainsThisScript;
                state["setActiveByName"] = &StateModule.setActiveByName;
                state["setDefaultActive"] = &StateModule.setDefaultActive;
                return state;
            }();
            env["time"] = () {
                LuaTable time = createTable;
                time["stdTimeHnsecs"] = &TimeModule.stdTimeHnsecs;
                time["unixTimeSeconds"] = &TimeModule.unixTimeSeconds;
                time["sleepMsecs"] = &TimeModule.sleepMsecs;
                time["waitFrames"] = &TimeModule.waitFrames;
                return time;
            }();
            env["mailbox"] = () {
                LuaTable mailbox = createTable;
                mailbox["consume"] = &MailboxModule.consume;
                return mailbox;
            }();

            return env;
        }
        catch (Exception e)
        {
            assert(false, "LuaLib: Fatal error creating env table: " ~ e.toString);
        }
    }

    private
    LuaScript script()
        => LuaScriptTask.instance.script;

    private
    const(LuaScript) constScript()
        => LuaScriptTask.constInstance.script;

    @trusted
    void log(LuaVariadic args)
    {
        string[] stringArgs;

        foreach (LuaValue arg; args)
        {
            final switch (arg.kind)
            {
                foreach (alias kind; EnumMembers!(LuaValue.Kind))
                {
            case kind:
                    auto val = arg.value!kind;
                    static if (is(typeof(val) == LuaNil))
                        stringArgs ~= "nil";
                    else
                        stringArgs ~= text(val);
                    break;
                }
            }
        }

        logInfo(`Lua script "%s" log: %-(%s%)`, constScript.name, stringArgs);
    }

    class LedModule
    {
        @disable this();
        @disable this(ref typeof(this));

    static:
        private
        shared(Led[]) leds()
            => LuaScriptTask.instance.script.leds;

        private
        const(shared(Led[])) constLeds()
            => leds;

        uint count()
            => cast(uint) constLeds.length;

        void set(uint index, ubyte r, ubyte g, ubyte b)
        {
            enforce!LuaLibException(
                index < leds.length,
                f!`Lua script "%s" led.set: Led index %u out of bounds for segment with length %u`(
                    constScript.name, index, leds.length,
            ),
            );
            leds[index] = Led(r, g, b);
        }

        void setSlice(uint begin, uint end, ubyte r, ubyte g, ubyte b)
        {
            enforce!LuaLibException(
                begin <= end,
                f!`Lua script "%s" led.setSlice: Begin index %u larger than end index %u`(
                    constScript.name, begin, end,
            ),
            );
            enforce!LuaLibException(
                end <= leds.length,
                f!`Lua script "%s" led.setSlice: End index %u out of bounds for segment with length %u"`(
                    constScript.name, end, leds.length,
            ),
            );
            leds[begin .. end] = Led(r, g, b);
        }

        void setAll(ubyte r, ubyte g, ubyte b)
        {
            leds[] = Led(r, g, b);
        }
    }

    class StateModule
    {
        @disable this();
        @disable this(ref typeof(this));

    static:
        string activeName()
            => Main.constInstance.states.activeState.name;

        bool activeContainsThisScript()
        {
            const Script thisScript = LuaScriptTask.constInstance.script;
            foreach (begin, const LedstripSegment seg; Main.instance.states.activeState.segments)
                if (seg.script is thisScript)
                    return true;
            return false;
        }

        void setActiveByName(string state)
        {
            Main.instance.states.setActiveState(state);
        }

        void setDefaultActive()
        {
            Main.instance.states.setDefaultActive;
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
            string name = LuaScriptTask.constInstance.script.name;
            enforce!LuaLibException(
                msecs >= 0,
                f!`Lua script "%s": Cannot sleep for less than %d msecs`(name, msecs),
            );
            sleep(msecs.msecs);
        }

        void waitFrames(ulong frames)
        {
            ulong frameCountAtEntry = frameCount;
            while (frameCount < frameCountAtEntry + frames)
                sleepMsecs(5);
        }
    }

    class MailboxModule
    {
        @disable this();
        @disable this(ref typeof(this));

    static:
        string consume(string topic)
            => Mailbox.consumeMailbox(topic);
    }
}

class LuaLibException : Exception
{
    mixin basicExceptionCtors;
}
