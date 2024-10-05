module script.lua.internal.lua_script_task;

import script.lua.internal.lua_lib : LuaLib;
import script.lua.lua_script : LuaScript;

import lumars : LuaState, LuaTable;

import vibe.core.concurrency : thisTid, Tid;
import vibe.core.log;
import vibe.core.task : Task;

@safe:
package:

package(script.lua) final  // @suppress(dscanner.suspicious.redundant_attributes)
class LuaScriptTask
{
    private static typeof(this)[Tid] tls_tidInstanceMap;

    private LuaScript m_script;
    private Task m_task;
    private LuaState m_luaState;
    private LuaTable m_env;

    package(script.lua) static nothrow
    void entrypoint(LuaScript script)
    {
        LuaScriptTask instance = new LuaScriptTask(script);
        instance.run;
    }

    @disable this(ref typeof(this));

    private nothrow
    this(LuaScript script)
    in (script !is null)
    {
        m_script = script;
        m_task = Task.getThis;
        registerInstance;
    }

    private nothrow  //
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

    private nothrow
    void run()
    {
        scope (exit)
            m_script.reset;

        createLuaState;
        buildEnv;

        try
        {
            (() @trusted => m_luaState.doString(m_script.sourceCode, m_env))();
        }
        catch (Exception e)
        {
            logError("Caught exception in LuaScriptTask.run: %s", e.msg);
            return;
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

    static nothrow
    LuaScriptTask instance()
    {
        Tid tid;
        try
            tid = thisTid;
        catch (Exception e)
            assert(false, (() @trusted => e.toString)());
        assert(tid in tls_tidInstanceMap);
        return tls_tidInstanceMap[tid];
    }

    static nothrow
    const(LuaScriptTask) constInstance()
        => instance;

    pure nothrow @nogc
    ref inout(LuaState) luaState() inout
    in (m_luaState != LuaState.init)
        => m_luaState;

    pure nothrow @nogc
    inout(LuaScript) script() inout
    in (m_script !is null)
        => m_script;
}
