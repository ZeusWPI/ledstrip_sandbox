module script.lua.internal.lua_lib;
// dfmt off

import ledstrip.led : Led;
import ledstrip.ledstrip : frameCount;
import ledstrip.ledstrip_states : LedstripStates;
import main : Main;
import script.lua.internal.lua_script_task : LuaScriptTask;
import webserver.mailbox : Mailbox;

import core.time : msecs;

import std.conv : text;
import std.datetime : Clock;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import std.string : toStringz;
import std.traits : EnumMembers;

import vibe.core.core : sleep, yield;
import vibe.core.log;

import bindbc.lua.v51 : lua_getglobal, lua_State;

import lumars;

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
            scope (exit) scriptTask.luaState.pop(1);
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
            env["led"] = ()
            {
                LuaTable led = createTable;
                led["count"] = LedModule.count; // Value
                led["set"] = &LedModule.set;
                led["setSlice"] = &LedModule.setSlice;
                led["setAll"] = &LedModule.setAll;
                led["isStateActive"] = &LedModule.isStateActive;
                led["setActiveState"] = &LedModule.setActiveState;
                return led;
            }();
            env["time"] = ()
            {
                LuaTable time = createTable;
                time["stdTimeHnsecs"] = &TimeModule.stdTimeHnsecs;
                time["unixTimeSeconds"] = &TimeModule.unixTimeSeconds;
                time["sleepMsecs"] = &TimeModule.sleepMsecs;
                time["waitFrames"] = &TimeModule.waitFrames;
                time["waitActiveState"] = &TimeModule.waitActiveState;
                time["waitInactiveState"] = &TimeModule.waitInactiveState;
                return time;
            }();
            env["mailbox"] = ()
            {
                LuaTable mailbox = createTable;
                mailbox["consume"] = &MailboxModule.consume;
                return mailbox;
            }();

            return env;
        }
        catch (Exception e)
        {
            assert(false, "Fatal error creating env table: " ~ e.toString);
        }
    }

    @trusted
    void log(LuaVariadic args)
    {
        string[] stringArgs;

        foreach (LuaValue arg; args)
            switch (arg.kind)
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
            default:
                break;
            }

        logInfo(`lua: %-(%s%)`, stringArgs);
    }

    class LedModule
    {
        @disable this();
        @disable this(ref typeof(this));

    static:
        private
        shared(Led[]) leds()
            => LuaScriptTask.instance.script.leds;

        uint count()
            => cast(uint) leds.length;

        void set(uint index, ubyte r, ubyte g, ubyte b)
        {
            enforce!LuaLibException(
                index < leds.length,
                f!"led.set: Led index %u out of bounds for segment with length %u"(index, leds.length)
            );
            leds[index] = Led(r, g, b);
        }

        void setSlice(uint begin, uint end, ubyte r, ubyte g, ubyte b)
        {
            enforce!LuaLibException(
                begin <= end,
                f!"led.setSlice: Begin index %u larger than end index %u"(begin, end)
            );
            enforce!LuaLibException(
                end <= leds.length,
                f!"led.setSlice: End index %u out of bounds for segment with length %u"(end, leds.length)
            );
            leds[begin .. end] = Led(r, g, b);
        }
        
        void setAll(ubyte r, ubyte g, ubyte b)
        {
            leds[] = Led(r, g, b);
        }
        
        bool isStateActive()
            => Main.instance.states.activeState.name != LuaScriptTask.instance.script.state;

        void setActiveState(string state)
        {
            Main.instance.states.setActiveState(state);
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
            enforce!LuaLibException(msecs >= 0, f!"Cannot sleep for less than %d msecs"(msecs));
            sleep(msecs.msecs);
        }

        void waitFrames(ulong frames)
        {
            ulong frameCountAtEntry = frameCount;
            while (frameCount < frameCountAtEntry + frames)
                sleepMsecs(5);
        }

        void waitActiveState()
        {
            while (Main.instance.states.activeState.name != LuaScriptTask.instance.script.state)
                sleepMsecs(5);
        }

        void waitInactiveState()
        {
            while (Main.instance.states.activeState.name == LuaScriptTask.instance.script.state)
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
