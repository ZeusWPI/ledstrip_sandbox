module script.script_instance_task;

import mailbox : Mailbox;
import script.script_instance : ScriptInstance;

import std.exception : basicExceptionCtors, enforce;

import vibe.core.concurrency : thisTid, Tid;
import vibe.core.log;
import vibe.core.task : Task;

@safe:

abstract
class ScriptInstanceTask
{
    private alias enf = enforce!ScriptInstanceTaskException;

    private static typeof(this)[Tid] tls_tidInstanceMap;

    protected ScriptInstance m_scriptInstance;
    protected Task m_task;

    private string[string] m_localMailbox;
    private Mailbox.Subscriber m_mailboxSubscriber;

    @disable this(ref typeof(this));

    protected
    this(ScriptInstance scriptInstance)
    {
        enf(scriptInstance !is null, "scriptInstance is null");
        m_scriptInstance = scriptInstance;
        m_task = Task.getThis;
        registerInstance;
        m_mailboxSubscriber = &mailboxSubscriberMethod;
    }

    protected nothrow  //
     ~this()
    {
        unregisterInstance;
        try
        {
            mailboxUnsubscribeAll;
        }
        catch (Exception e)
        {
            logError("Exception in ScriptInstanceTask dtor: %s", (() @trusted => e.toString)());
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

    protected abstract nothrow
    void run();

    static nothrow
    ScriptInstanceTask instance()
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
    const(ScriptInstanceTask) constInstance()
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

class ScriptInstanceTaskException : Exception
{
    mixin basicExceptionCtors;
}
