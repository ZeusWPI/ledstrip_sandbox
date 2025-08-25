module script.lua.lua_script_instance_thread;

import script.lua.lua_lib : LuaLib;
import script.lua.lua_script_instance : LuaScriptInstance;
import script.script_instance : ScriptInstance;
import script.script_instance_thread : ScriptInstanceThread;
import thread_manager : inThreadKind, ThreadKind;

import std.algorithm : canFind;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;

import lumars : LuaState, LuaTable;

import vibe.core.log;

@safe:

final
class LuaScriptInstanceThread : ScriptInstanceThread
{
    private alias enf = enforce!LuaScriptInstanceThreadException;

    private LuaState m_luaState;
    private LuaTable m_env; // Has @system dtor

    static nothrow
    void entrypoint(ScriptInstance scriptInstance)
    in (inThreadKind(ThreadKind.scriptInstance), "LuaScriptInstanceThread: entrypoint must be called from a script instance thread")
    {
        LuaScriptInstanceThread instance;
        try
            instance = new typeof(this)(scriptInstance);
        catch (Exception e)
            logError("LuaScriptInstanceThread entrypoint failed: %s", (() @trusted => e.toString)());
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

        logInfo(`Thread for lua script instance "%s" started`, m_scriptInstance.name);

        createLuaState;
        buildEnv;

        try
        {
            (() @trusted => m_luaState.doString(m_scriptInstance.sourceCode, m_env))();
            logInfo(`Thread for lua script instance "%s" exited normally`, m_scriptInstance.name);
        }
        catch (Exception e)
        {
            logError(
                `Thread for lua script instance "%s" failed: %s`,
                m_scriptInstance.name, (() @trusted => e.toString)(),
            );
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
                f!`Thread for lua script instance "%s": Fatal error creating LuaState: %s`(
                    m_scriptInstance.name, e.toString,
            ),
            );
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
            assert(false, f!`Thread for lua script instance "%s": Fatal error building env: %s`(
                    m_scriptInstance.name, e.toString,
            ));
        }
    }

    static nothrow
    LuaScriptInstanceThread instance()
        => cast(LuaScriptInstanceThread) super.instance;

    static nothrow
    const(LuaScriptInstanceThread) constInstance()
        => cast(const(LuaScriptInstanceThread)) super.constInstance;

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

class LuaScriptInstanceThreadException : Exception
{
    mixin basicExceptionCtors;
}
