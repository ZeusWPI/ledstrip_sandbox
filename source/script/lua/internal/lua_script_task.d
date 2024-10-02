module script.lua.internal.lua_script_task;
// dfmt off

import script.lua.internal.lua_lib : LuaLib;
import script.lua.lua_script : LuaScript;

import core.time : Duration;

import std.array : array;
import std.conv : to;
import std.stdio : writefln, writeln;
import std.string : toStringz;

import lumars : LuaFunc, LuaNil, LuaState, LuaTable, LuaValue, LuaVariadic;

import vibe.core.concurrency : thisTid, Tid;
import vibe.core.log;
import vibe.core.task : InterruptException, Task;

@safe:
package:

package(script.lua) final // @suppress(dscanner.suspicious.redundant_attributes)
class LuaScriptTask
{
    private static typeof(this)[Tid] tls_tidInstanceMap;

    private LuaScript m_script;
    private Task m_task;
    private LuaState m_luaState;
    private LuaTable m_env;

    @disable this(ref typeof(this));

    private nothrow
    this(LuaScript script)
    in (script !is null)
    {
        m_script = script;
        m_task = Task.getThis;
        registerInstance;
    }

    private nothrow
    ~this()
    {
        unregisterInstance;
    }

    private nothrow
    void registerInstance()
    {
        tls_tidInstanceMap[m_task.tid] = this;
    }

    private nothrow
    void unregisterInstance()
    {
        tls_tidInstanceMap.remove(m_task.tid);
    }

    private nothrow @trusted
    void run()
    {
        scope (exit) m_script.reset;

        createLuaState;
        buildEnv;

        try
        {
            m_luaState.doString(m_script.scriptString, m_env);
        }
        catch (InterruptException e)
        {
            logInfo("lua script task interrupted");
            return;
        }
        catch (Exception e)
        {
            logError("Caught exception in LuaScriptTask.run: %s", e.toString);
        }
        logInfo("lua script task exited normally");
    }

    private nothrow @trusted
    void createLuaState()
    in (m_luaState == LuaState.init)
    out (; m_luaState != LuaState.init)
    {
        try
        {
            m_luaState = LuaState(null);
        }
        catch (Exception e)
        {
            assert(false, "Fatal error creating LuaState: " ~ e.toString);
        }
    }

    private nothrow @trusted
    void buildEnv()
    in (m_env == LuaTable.init)
    out (; m_env != LuaTable.init)
    {
        try
        {
            m_env = LuaLib.buildEnv(this);
        }
        catch (Exception e)
        {
            assert(false, "Fatal error building env: " ~ e.toString);
        }
    }

    package(script.lua) static nothrow
    void entrypoint(LuaScript script)
    {
        LuaScriptTask instance = new LuaScriptTask(script);
        instance.run;
    }

    static nothrow
    LuaScriptTask instance()
    {
        Tid tid;
        try tid = thisTid;
        catch (Exception e) assert(false, (() @trusted => e.toString)());
        assert(tid in tls_tidInstanceMap);
        return tls_tidInstanceMap[tid];
    }

    pure nothrow @nogc
    ref LuaState luaState()
    in (m_luaState != LuaState.init)
        => m_luaState;

    pure nothrow @nogc
    LuaScript script()
    in (m_script !is null)
        => m_script;
}
