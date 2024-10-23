module script.lua.internal.lua_script_task;

import mailbox : Mailbox;
import script.lua.internal.lua_lib : LuaLib;
import script.lua.lua_script : LuaScript;
import script.script : Script;

import std.algorithm : canFind;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;

import lumars : LuaState, LuaTable;

import vibe.core.concurrency : thisTid, Tid;
import vibe.core.core : yield;
import vibe.core.log;
import vibe.core.task : Task;

import bindbc.lua.v51 : lua_Debug, lua_Hook, LUA_MASKLINE, lua_sethook, lua_State;

@safe:
package:

package(script.lua) final  // @suppress(dscanner.suspicious.redundant_attributes)
class LuaScriptTask
{
    private alias enf = enforce!LuaScriptTaskException;

    private static typeof(this)[Tid] tls_tidInstanceMap;

    private LuaScript m_script;
    private Task m_task;

    private string[string] m_localMailbox;
    private Mailbox.Subscriber m_mailboxSubscriber;

    private LuaState m_luaState;
    private LuaTable m_env;

    package(script.lua) static nothrow
    void entrypoint(Script script)
    {
        LuaScriptTask instance = new LuaScriptTask(script);
        instance.run;
    }

    @disable this(ref typeof(this));

    private nothrow
    this(Script script)
    in (script !is null, "Lua script task: script is null")
    in ((cast(LuaScript) script) !is null, "Lua script task: script is not a LuaScript")
    {
        m_script = cast(LuaScript) script;
        m_task = Task.getThis;
        registerInstance;
        m_mailboxSubscriber = &mailboxSubscriber;
    }

    private nothrow  //
     ~this()
    {
        unregisterInstance;
        try
        {
            mailboxUnsubscribeAll;
        }
        catch (Exception e)
        {
            logError("Exception in LuaScriptTask dtor: %s", (() @trusted => e.toString)());
        }
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
                logInfo(`Task for bf script "%s" exited by interruption`, m_script.name);
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

    private
    void mailboxSubscriber(string topic, string message)
    {
        m_localMailbox[topic] = message;
    }

    void mailboxSubscribe(string topic)
    {
        Mailbox.instance.subscribe(topic, m_mailboxSubscriber);
    }

    void mailboxUnsubscribe(string topic)
    {
        Mailbox.instance.unsubscribe(topic, m_mailboxSubscriber);
    }

    void mailboxUnsubscribeAll()
    {
        Mailbox.instance.unsubscribeAll(m_mailboxSubscriber);
    }

    string mailboxConsume(string topic)
    {
        if (topic in m_localMailbox)
        {
            scope (exit)
                m_localMailbox.remove(topic);
            return m_localMailbox[topic];
        }
        return "";
    }

    pure nothrow @nogc
    ref inout(LuaState) luaState() inout
    in (m_luaState != LuaState.init)
        => m_luaState;

    pure nothrow @nogc
    inout(LuaScript) script() inout
    in (m_script !is null)
        => m_script;
}

class LuaScriptTaskException : Exception
{
    mixin basicExceptionCtors;
}
