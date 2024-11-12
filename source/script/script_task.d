module script.script_task;

import mailbox : Mailbox;
import script.script : Script;

import std.exception : basicExceptionCtors, enforce;

import vibe.core.concurrency : thisTid, Tid;
import vibe.core.log;
import vibe.core.task : Task;

@safe:

abstract
class ScriptTask
{
    private alias enf = enforce!ScriptTaskException;

    private static typeof(this)[Tid] tls_tidInstanceMap;

    protected Script m_script;
    protected Task m_task;

    private string[string] m_localMailbox;
    private Mailbox.Subscriber m_mailboxSubscriber;

    @disable this(ref typeof(this));

    protected
    this(Script script)
    {
        enf(script !is null, "Script is null");
        m_script = script;
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
            logError("Exception in ScriptTask dtor: %s", (() @trusted => e.toString)());
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
    ScriptTask instance()
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
    const(ScriptTask) constInstance()
        => cast(const) instance;

    final pure nothrow @nogc
    Script script()
        => m_script;

    final pure nothrow @nogc
    const(Script) constScript() const
        => m_script;

    private
    void mailboxSubscriberMethod(string topic, string message)
    {
        synchronized
        {
            m_localMailbox[topic] = message;
        }
    }

    final
    void mailboxSubscribe(string topic)
    {
        synchronized
        {
            Mailbox.instance.subscribe(topic, m_mailboxSubscriber);
        }
    }

    final
    void mailboxUnsubscribe(string topic)
    {
        synchronized
        {
            Mailbox.instance.unsubscribe(topic, m_mailboxSubscriber);
        }
    }

    final
    void mailboxUnsubscribeAll()
    {
        synchronized
        {
            Mailbox.instance.unsubscribeAll(m_mailboxSubscriber);
        }
    }

    final
    string mailboxConsume(string topic)
    {
        synchronized
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

class ScriptTaskException : Exception
{
    mixin basicExceptionCtors;
}
