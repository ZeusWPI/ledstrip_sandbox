module script.lua.lua_lib;
// dfmt off

import script.common_lib : CommonLib;
import script.lua.lua_script_instance : LuaScriptInstance;
import script.lua.lua_script_instance_thread : LuaScriptInstanceThread;

import std.conv : text;
import std.exception : basicExceptionCtors, enforce;
import std.string : toStringz;
import std.traits : EnumMembers;

import vibe.core.log;

import bindbc.lua.v51 : lua_getglobal;

import lumars : LuaFunc, LuaNil, LuaNumber, LuaTable, LuaValue, LuaVariadic;

@safe:

class LuaLib
{
    private alias enf = enforce!LuaLibException;

    @disable this();
    @disable this(ref typeof(this));

static:
    nothrow @trusted
    LuaTable buildEnv(LuaScriptInstanceThread scriptInstanceThread)
    {
        LuaTable createTable()
        {
            return LuaTable.makeNew(&scriptInstanceThread.luaState());
        }

        T getGlobal(T)(string key)
        {
            lua_getglobal(scriptInstanceThread.luaState.handle, key.toStringz);
            scope (exit)
                scriptInstanceThread.luaState.pop(1);
            return scriptInstanceThread.luaState.get!T(scriptInstanceThread.luaState.top);
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
            register(&LuaLib.log, "", "log");

            // Led module
            register(CommonLib.LedModule.count,     "led", "count"   );
            register(&CommonLib.LedModule.set,      "led", "set"     );
            register(&CommonLib.LedModule.setSlice, "led", "setSlice");
            register(&CommonLib.LedModule.setAll,   "led", "setAll"  );

            // State module
            register(&CommonLib.StateModule.activeName,                       "state", "activeName"                      );
            register(&CommonLib.StateModule.activeContainsThisScriptInstance, "state", "activeContainsThisScriptInstance");
            register(&CommonLib.StateModule.setActiveByName,                  "state", "setActiveByName"                 );
            register(&CommonLib.StateModule.setDefaultActive,                 "state", "setDefaultActive"                );

            // Time module
            register(&CommonLib.TimeModule.stdTimeHnsecs,   "time", "stdTimeHnsecs"  );
            register(&CommonLib.TimeModule.unixTimeSeconds, "time", "unixTimeSeconds");
            register(&CommonLib.TimeModule.sleepMsecs,      "time", "sleepMsecs"     );
            register(&CommonLib.TimeModule.waitFrames,      "time", "waitFrames"     );

            // Mailbox module
            register(&CommonLib.MailboxModule.subscribe,      "mailbox", "subscribe"     );
            register(&CommonLib.MailboxModule.unsubscribe,    "mailbox", "unsubscribe"   );
            register(&CommonLib.MailboxModule.unsubscribeAll, "mailbox", "unsubscribeAll");
            register(&CommonLib.MailboxModule.consume,        "mailbox", "consume"       );

            return env;
        }
        catch (Exception e)
        {
            assert(false, "LuaLib: Fatal error creating env table: " ~ e.toString);
        }
    }

    private
    LuaScriptInstanceThread thread()
        => LuaScriptInstanceThread.instance;

    private
    const(LuaScriptInstanceThread) constThread()
        => LuaScriptInstanceThread.constInstance;

    private
    LuaScriptInstance scriptInstance()
        => thread.luaScriptInstance;

    private
    const(LuaScriptInstance) constScriptInstance()
        => constThread.constLuaScriptInstance;

    @trusted
    void log(LuaVariadic args)
    {
        string[] stringArgs;

        foreach (LuaValue arg; args)
        {
            sw: final switch (arg.kind)
            {
                static foreach (alias kind; EnumMembers!(LuaValue.Kind))
                {
            case kind:
                    auto val = arg.value!kind;
                    static if (is(typeof(val) == LuaNil))
                        stringArgs ~= "nil";
                    else
                        stringArgs ~= text(val);
                    break sw;
                }
            }
        }

        logInfo(`Script instance "%s": log: %-(%s%)`, constScriptInstance.name, stringArgs);
    }
}

class LuaLibException : Exception
{
    mixin basicExceptionCtors;
}
