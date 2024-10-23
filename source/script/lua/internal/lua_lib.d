module script.lua.internal.lua_lib;
// dfmt off

import ledstrip.led : Led;
import ledstrip.ledstrip : Ledstrip;
import ledstrip.ledstrip_segment : LedstripSegment;
import ledstrip.ledstrip_states : LedstripStates;
import script.lua.internal.lua_script_task : LuaScriptTask;
import script.lua.lua_script : LuaScript;
import script.script : Script;
import util : sleepFrameFraction;
import mailbox : Mailbox;

import core.time : msecs;

import std.conv : text;
import std.datetime : Clock;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;
import std.string : toStringz;
import std.traits : EnumMembers, isFunctionPointer;

import vibe.core.core : sleep;
import vibe.core.log;

import bindbc.lua.v51 : lua_getglobal;

import lumars : LuaFunc, LuaNil, LuaTable, LuaValue, LuaVariadic, addFunction, LuaNumber;

@safe:

class LuaLib
{
    private alias enf = enforce!LuaLibException;

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

        try
        {
            LuaTable env = createTable;

            void ensureModuleExists(string module_)
            {
                bool moduleExists;
                env.tryGet!LuaTable(module_, moduleExists);
                if (!moduleExists)
                    env.set(module_, createTable);
            }

            void register(T)(T val, string module_, string name)
            {
                if (module_.length)
                {
                    ensureModuleExists(module_);
                    env.get!LuaTable(module_).set(name, val);
                }
                else
                {
                    env.set(name, val);
                }
            }

            void registerGlobal(T)(string module_, string name)
            {
                T val;
                if (module_.length)
                    val = getGlobal!LuaTable(module_).get!T(name);
                else
                    val = getGlobal!T(name);
                register!T(val, module_, name);
            }

            // Values
            registerGlobal!(string)("", "_VERSION");

            // Core
            registerGlobal!(LuaFunc)("", "type");

            // Error handling
            registerGlobal!(LuaFunc)("", "assert");
            registerGlobal!(LuaFunc)("", "error" );
            registerGlobal!(LuaFunc)("", "pcall" );
            registerGlobal!(LuaFunc)("", "xpcall");

            // String ops
            registerGlobal!(LuaFunc)("",       "tonumber");
            registerGlobal!(LuaFunc)("",       "tostring");
            registerGlobal!(LuaFunc)("",       "unpack"  );
            registerGlobal!(LuaFunc)("string", "byte"    );
            registerGlobal!(LuaFunc)("string", "char"    );
            registerGlobal!(LuaFunc)("string", "dump"    );
            registerGlobal!(LuaFunc)("string", "find"    );
            registerGlobal!(LuaFunc)("string", "format"  );
            registerGlobal!(LuaFunc)("string", "gmatch"  );
            registerGlobal!(LuaFunc)("string", "gsub"    );
            registerGlobal!(LuaFunc)("string", "len"     );
            registerGlobal!(LuaFunc)("string", "lower"   );
            registerGlobal!(LuaFunc)("string", "match"   );
            registerGlobal!(LuaFunc)("string", "rep"     );
            registerGlobal!(LuaFunc)("string", "reverse" );
            registerGlobal!(LuaFunc)("string", "sub"     );
            registerGlobal!(LuaFunc)("string", "upper"   );

            // Table ops
            registerGlobal!(LuaFunc)("",      "ipairs");
            registerGlobal!(LuaFunc)("",      "next"  );
            registerGlobal!(LuaFunc)("",      "pairs" );
            registerGlobal!(LuaFunc)("",      "select");
            registerGlobal!(LuaFunc)("table", "concat");
            registerGlobal!(LuaFunc)("table", "insert");
            registerGlobal!(LuaFunc)("table", "maxn"  );
            registerGlobal!(LuaFunc)("table", "remove");
            registerGlobal!(LuaFunc)("table", "sort"  );

            // Math
            registerGlobal!(LuaFunc  )("math", "abs"       );
            registerGlobal!(LuaFunc  )("math", "acos"      );
            registerGlobal!(LuaFunc  )("math", "asin"      );
            registerGlobal!(LuaFunc  )("math", "atan"      );
            registerGlobal!(LuaFunc  )("math", "atan2"     );
            registerGlobal!(LuaFunc  )("math", "ceil"      );
            registerGlobal!(LuaFunc  )("math", "cos"       );
            registerGlobal!(LuaFunc  )("math", "cosh"      );
            registerGlobal!(LuaFunc  )("math", "deg"       );
            registerGlobal!(LuaFunc  )("math", "exp"       );
            registerGlobal!(LuaFunc  )("math", "floor"     );
            registerGlobal!(LuaFunc  )("math", "fmod"      );
            registerGlobal!(LuaFunc  )("math", "frexp"     );
            registerGlobal!(LuaNumber)("math", "huge"      );
            registerGlobal!(LuaFunc  )("math", "ldexp"     );
            registerGlobal!(LuaFunc  )("math", "log"       );
            registerGlobal!(LuaFunc  )("math", "log10"     );
            registerGlobal!(LuaFunc  )("math", "max"       );
            registerGlobal!(LuaFunc  )("math", "min"       );
            registerGlobal!(LuaFunc  )("math", "modf"      );
            registerGlobal!(LuaNumber)("math", "pi"        );
            registerGlobal!(LuaFunc  )("math", "pow"       );
            registerGlobal!(LuaFunc  )("math", "rad"       );
            registerGlobal!(LuaFunc  )("math", "random"    );
            registerGlobal!(LuaFunc  )("math", "randomseed");
            registerGlobal!(LuaFunc  )("math", "sin"       );
            registerGlobal!(LuaFunc  )("math", "sinh"      );
            registerGlobal!(LuaFunc  )("math", "sqrt"      );
            registerGlobal!(LuaFunc  )("math", "tan"       );
            registerGlobal!(LuaFunc  )("math", "tanh"      );

            // Bit manipulation
            registerGlobal!(LuaFunc)("bit", "arshift");
            registerGlobal!(LuaFunc)("bit", "band"   );
            registerGlobal!(LuaFunc)("bit", "bnot"   );
            registerGlobal!(LuaFunc)("bit", "bor"    );
            registerGlobal!(LuaFunc)("bit", "bswap"  );
            registerGlobal!(LuaFunc)("bit", "bxor"   );
            registerGlobal!(LuaFunc)("bit", "lshift" );
            registerGlobal!(LuaFunc)("bit", "rol"    );
            registerGlobal!(LuaFunc)("bit", "ror"    );
            registerGlobal!(LuaFunc)("bit", "rshift" );
            registerGlobal!(LuaFunc)("bit", "tobit"  );
            registerGlobal!(LuaFunc)("bit", "tohex"  );

            // Custom globals
            register(&log, "", "log");

            // Led module
            register(LedModule.count,     "led", "count"   );
            register(&LedModule.set,      "led", "set"     );
            register(&LedModule.setSlice, "led", "setSlice");
            register(&LedModule.setAll,   "led", "setAll"  );

            // State module
            register(&StateModule.activeName,               "state", "activeName"              );
            register(&StateModule.activeContainsThisScript, "state", "activeContainsThisScript");
            register(&StateModule.setActiveByName,          "state", "setActiveByName"         );
            register(&StateModule.setDefaultActive,         "state", "setDefaultActive"        );

            // Time module
            register(&TimeModule.stdTimeHnsecs,   "time", "stdTimeHnsecs"  );
            register(&TimeModule.unixTimeSeconds, "time", "unixTimeSeconds");
            register(&TimeModule.sleepMsecs,      "time", "sleepMsecs"     );
            register(&TimeModule.waitFrames,      "time", "waitFrames"     );

            // Mailbox module
            register(&MailboxModule.subscribe,      "mailbox", "subscribe"     );
            register(&MailboxModule.unsubscribe,    "mailbox", "unsubscribe"   );
            register(&MailboxModule.unsubscribeAll, "mailbox", "unsubscribeAll");
            register(&MailboxModule.consume,        "mailbox", "consume"       );

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

        private
        void setLedsChanged()
            => LuaScriptTask.instance.script.setLedsChanged;

        uint count()
            => cast(uint) constLeds.length;

        void set(uint index, ubyte r, ubyte g, ubyte b)
        {
            enf(
                index < constLeds.length,
                f!`Lua script "%s" led.set: Led index %u out of bounds for segment with length %u`(
                    constScript.name, index, constLeds.length,
            ),
            );
            leds[index] = Led(r, g, b);
            setLedsChanged;
        }

        void setSlice(uint begin, uint end, ubyte r, ubyte g, ubyte b)
        {
            enf(
                begin <= end,
                f!`Lua script "%s" led.setSlice: Begin index %u larger than end index %u`(
                    constScript.name, begin, end,
            ),
            );
            enf(
                end <= constLeds.length,
                f!`Lua script "%s" led.setSlice: End index %u out of bounds for segment with length %u"`(
                    constScript.name, end, constLeds.length,
            ),
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
            const Script thisScript = LuaScriptTask.constInstance.script;
            foreach (begin, const LedstripSegment seg; LedstripStates
                .constInstance.activeState.segments)
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
            string name = LuaScriptTask.constInstance.script.name;
            enf(
                msecs >= 0,
                f!`Lua script "%s": Cannot sleep for less than %d msecs`(name, msecs),
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
            LuaScriptTask.instance.mailboxSubscribe(topic);
        }

        void unsubscribe(string topic)
        {
            LuaScriptTask.instance.mailboxUnsubscribe(topic);
        }

        void unsubscribeAll()
        {
            LuaScriptTask.instance.mailboxUnsubscribeAll();
        }

        string consume(string topic)
            => LuaScriptTask.instance.mailboxConsume(topic);
    }
}

class LuaLibException : Exception
{
    mixin basicExceptionCtors;
}
