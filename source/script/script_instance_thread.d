module script.script_instance_thread;

import mailbox : Mailbox;
import script.script_instance : ScriptInstance;
import thread_manager : inThreadKind, ThreadKind;

import std.concurrency : thisTid, Tid;
import std.exception : basicExceptionCtors, enforce;

import vibe.core.log;

import core.sync.mutex : Mutex;

@safe:

abstract
class ScriptInstanceThread
{
    private alias enf = enforce!ScriptInstanceThreadException;

    private __gshared typeof(this)[Tid] g_tidInstanceMap;
    private static shared Mutex g_tidInstanceMapMutex;

    shared static this()
    {
        g_tidInstanceMapMutex = new shared Mutex;
    }

    protected ScriptInstance m_scriptInstance;
    protected Tid m_tid;

    private string[string] m_localMailbox;
    private Mailbox.Subscriber m_mailboxSubscriber;

    @disable this(ref typeof(this));

    protected
    this(ScriptInstance scriptInstance)
    in (inThreadKind(ThreadKind.scriptInstance))
    {
        enf(scriptInstance !is null, "scriptInstance is null");
        m_scriptInstance = scriptInstance;
        m_tid = thisTid;
        registerInstance;
        m_mailboxSubscriber = &mailboxSubscriberMethod;
    }

    protected nothrow  //
     ~this()
    in (inThreadKind(ThreadKind.scriptInstance))
    {
        unregisterInstance;
        try
        {
            mailboxUnsubscribeAll;
        }
        catch (Exception e)
        {
            logError("Exception in ScriptInstanceThread dtor: %s", (() @trusted => e.toString)());
        }
    }

    private nothrow @trusted
    void registerInstance()
    {
        g_tidInstanceMapMutex.lock_nothrow;
        scope(exit) g_tidInstanceMapMutex.unlock_nothrow;

        g_tidInstanceMap[m_tid] = this;
    }

    private nothrow @trusted
    void unregisterInstance()
    {
        g_tidInstanceMapMutex.lock_nothrow;
        scope(exit) g_tidInstanceMapMutex.unlock_nothrow;

        g_tidInstanceMap.remove(m_tid);
    }

    protected abstract nothrow
    void run();

    static nothrow @trusted
    ScriptInstanceThread instance()
    {
        Tid tid;
        try
            tid = thisTid;
        catch (Exception e)
            assert(false, (() @trusted => e.toString)());

        g_tidInstanceMapMutex.lock_nothrow;
        scope(exit) g_tidInstanceMapMutex.unlock_nothrow;

        assert(tid in g_tidInstanceMap);
        return g_tidInstanceMap[tid];
    }

    static nothrow
    const(ScriptInstanceThread) constInstance()
        => cast(const) instance;

    final pure nothrow @nogc
    ScriptInstance scriptInstance()
        => m_scriptInstance;

    final pure nothrow @nogc
    const(ScriptInstance) constScriptInstance() const
        => m_scriptInstance;

    private
    void mailboxSubscriberMethod(string topic, string message)
    {
        synchronized (this)
        {
            m_localMailbox[topic] = message;
        }
    }

    final
    void mailboxSubscribe(string topic)
    {
        synchronized (this)
        {
            Mailbox.instance.subscribe(topic, m_mailboxSubscriber);
        }
    }

    final
    void mailboxUnsubscribe(string topic)
    {
        synchronized (this)
        {
            Mailbox.instance.unsubscribe(topic, m_mailboxSubscriber);
        }
    }

    final
    void mailboxUnsubscribeAll()
    {
        synchronized (this)
        {
            Mailbox.instance.unsubscribeAll(m_mailboxSubscriber);
        }
    }

    final
    string mailboxConsume(string topic)
    {
        synchronized (this)
        {
            enf(topic.length, "Topic cannot be empty");
            if (topic in m_localMailbox)
            {
                scope (exit)
                    m_localMailbox.remove(topic);
                return m_localMailbox[topic];
            }
            return "";
        }
    }
}

class ScriptInstanceThreadException : Exception
{
    mixin basicExceptionCtors;
}
