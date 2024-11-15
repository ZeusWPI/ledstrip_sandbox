module script.lua.lua_script_instance_task;

import script.lua.lua_lib : LuaLib;
import script.lua.lua_script_instance : LuaScriptInstance;
import script.script_instance : ScriptInstance;
import script.script_instance_task : ScriptInstanceTask;
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
class LuaScriptInstanceTask : ScriptInstanceTask
{
    private alias enf = enforce!LuaScriptInstanceTaskException;

    private LuaState m_luaState;
    private LuaTable m_env; // Has @system dtor

    static nothrow
    void entrypoint(ScriptInstance scriptInstance)
    in (
        ThreadManager.constInstance.inScriptInstanceTaskPool,
        "LuaScriptInstanceTask: entrypoint must be called from a script instance task",
    )
    {
        LuaScriptInstanceTask instance;
        try
            instance = new typeof(this)(scriptInstance);
        catch (Exception e)
            logError("LuaScriptInstanceTask entrypoint failed: %s", (() @trusted => e.toString)());
        instance.run;
    }

    protected @trusted // Calls @system dtor on throw
    this(ScriptInstance scriptInstance)
    {
        super(scriptInstance);
        enf(cast(LuaScriptInstance) scriptInstance, "scriptInstance is not a LuaScriptInstance");
    }

    protected override nothrow
    void run()
    {
        scope (exit)
        {
            m_scriptInstance.setStopped;
        }

        logInfo(`Task for lua script instance "%s" started`, m_scriptInstance.name);

        createLuaState;
        setupHook;
        buildEnv;

        try
        {
            (() @trusted => m_luaState.doString(m_scriptInstance.sourceCode, m_env))();
            logInfo(`Task for lua script instance "%s" exited normally`, m_scriptInstance.name);
        }
        catch (Exception e)
        {
            // An InterruptException gets rethrown as a LuaException with the msg embedded
            if (e.msg.canFind("interrupted"))
            {
                logInfo(`Task for lua script instance "%s" exited by interruption`, m_scriptInstance.name);
            }
            else
            {
                logError(
                    `Task for lua script instance "%s" failed: %s`,
                    m_scriptInstance.name, (() @trusted => e.toString)(),
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
                f!`Task for lua script instance "%s": Fatal error creating LuaState: %s`(
                    m_scriptInstance.name, e.toString,
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
                f!`Task for lua script instance "%s": Fatal error building env: %s`(
                    m_scriptInstance.name, e.toString,
            ),
            );
        }
    }

    static nothrow
    LuaScriptInstanceTask instance()
        => cast(LuaScriptInstanceTask) super.instance;

    static nothrow
    const(LuaScriptInstanceTask) constInstance()
        => cast(const(LuaScriptInstanceTask)) super.constInstance;

    pure nothrow @nogc
    LuaScriptInstance luaScriptInstance()
        => cast(LuaScriptInstance) scriptInstance;

    pure nothrow @nogc
    const(LuaScriptInstance) constLuaScriptInstance() const
        => cast(const(LuaScriptInstance)) constScriptInstance;

    pure nothrow @nogc
    ref inout(LuaState) luaState() inout
    in (m_luaState != LuaState.init)
        => m_luaState;
}

class LuaScriptInstanceTaskException : Exception
{
    mixin basicExceptionCtors;
}
