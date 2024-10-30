module script.lua.lua_script_task;

import script.lua.lua_lib : LuaLib;
import script.lua.lua_script : LuaScript;
import script.script : Script;
import script.script_task : ScriptTask;
import thread_manager : ThreadManager;

import std.algorithm : canFind;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;

import lumars : LuaState, LuaTable;

import vibe.core.core : yield;
import vibe.core.log;

import bindbc.lua.v51 : lua_Debug, lua_Hook, LUA_MASKLINE, lua_sethook, lua_State;

@safe:

final
class LuaScriptTask : ScriptTask
{
    private alias enf = enforce!LuaScriptTaskException;

    private LuaState m_luaState;
    private LuaTable m_env; // Has @system dtor

    static nothrow
    void entrypoint(Script script)
    in (
        ThreadManager.constInstance.inScriptTaskPool,
        "LuaScriptTask: entrypoint must be called from a script task",
    )
    {
        LuaScriptTask instance;
        try
            instance = new typeof(this)(script);
        catch (Exception e)
            logError("LuaScriptTask entrypoint failed: %s", (() @trusted => e.toString)());
        instance.run;
    }

    protected @trusted // Calls @system dtor on throw
    this(Script script)
    {
        super(script);
        enf(cast(LuaScript) script, "Script is not a LuaScript");
    }

    protected override nothrow
    void run()
    {
        scope (exit)
        {
            m_script.setStopped;
        }

        logInfo(`Task for lua script "%s" started`, m_script.name);

        createLuaState;
        setupHook;
        buildEnv;

        try
        {
            (() @trusted => m_luaState.doString(m_script.sourceCode, m_env))();
            logInfo(`Task for lua script "%s" exited normally`, m_script.name);
        }
        catch (Exception e)
        {
            // An InterruptException gets rethrown as a LuaException with the msg embedded
            if (e.msg.canFind("interrupted"))
            {
                logInfo(`Task for lua script "%s" exited by interruption`, m_script.name);
            }
            else
            {
                logError(
                    `Task for lua script "%s" failed: %s`,
                    m_script.name, (() @trusted => e.toString)(),
                );
            }
        }
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
            assert(
                false,
                f!`Task for lua script "%s": Fatal error creating LuaState: %s`(
                    m_script.name, e.toString,
            ),
            );
        }
    }

    private nothrow @trusted
    void setupHook()
    {
        lua_sethook(
            m_luaState.handle,
            cast(lua_Hook)&hook, // Cast away nothrow so yield can raise an InterruptException
            LUA_MASKLINE,
            0,
        );
    }

    private static
    void hook(lua_State* handle, lua_Debug* dbg)
    {
        yield;
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
            assert(
                false,
                f!`Task for lua script "%s": Fatal error building env: %s`(
                    m_script.name, e.toString,
            ),
            );
        }
    }

    static nothrow
    LuaScriptTask instance()
        => cast(LuaScriptTask) uncastedInstance;

    static nothrow
    const(LuaScriptTask) constInstance()
        => cast(const(LuaScriptTask)) uncastedInstance;

    pure nothrow @nogc
    inout(LuaScript) script() inout
        => cast(inout(LuaScript)) uncastedScript;

    pure nothrow @nogc
    ref inout(LuaState) luaState() inout
    in (m_luaState != LuaState.init)
        => m_luaState;
}

class LuaScriptTaskException : Exception
{
    mixin basicExceptionCtors;
}
