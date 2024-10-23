module mailbox;

import singleton : sharedSingleton;

import std.algorithm : canFind, countUntil, remove;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;

import vibe.core.log;

@safe:

final shared
class Mailbox
{
    mixin sharedSingleton;

    private alias enf = enforce!MailboxException;

    alias Subscriber = void delegate(string topic, string message);

    private Subscriber[][string] m_mailbox;

    private nothrow
    this()
    {
    }

    synchronized
    void subscribe(string topic, Subscriber subscriber)
    {
        enforceValidTopic("subscribe", topic);
        enforceValidSubscriber("subscribe", subscriber);
        if (topic !in m_mailbox)
            m_mailbox[topic] = [];
        enf(!m_mailbox[topic].canFind(subscriber), "subscribe: Subscriber already exists");
        m_mailbox[topic] ~= subscriber;
    }

    synchronized
    void unsubscribe(string topic, Subscriber subscriber)
    {
        enforceValidTopic("unsubscribe", topic);
        enforceValidSubscriber("unsubscribe", subscriber);
        enf(topic in m_mailbox, f!`unsubscribe: unknown topic "%s"`(topic));
        ptrdiff_t index = m_mailbox[topic].countUntil(subscriber);
        enf(index >= 0, "unsubscribe: not subscribed");
        m_mailbox[topic] = m_mailbox[topic].remove(index);
    }

    synchronized
    void unsubscribeAll(Subscriber subscriber)
    {
        enforceValidSubscriber("unsubscribeAll", subscriber);
        foreach (topic, ref subscribers; m_mailbox)
        {
            ptrdiff_t index = subscribers.countUntil(subscriber);
            if (index >= 0)
                subscribers = subscribers.remove(index);
        }
    }

    synchronized
    void put(string topic, string message)
    {
        enforceValidTopic("put", topic);
        enforceValidMessage("put", message);
        if (topic in m_mailbox)
        {
            foreach (Subscriber subscriber; m_mailbox[topic])
                subscriber(topic, message);
        }
    }

    private static
    void enforceValidTopic(string method, string topic)
    {
        enf(topic.length, f!`%s: Topic cannot be empty`(method));
    }

    private static
    void enforceValidSubscriber(string method, Subscriber subscriber)
    {
        enf(subscriber !is null, f!`%s: Subscriber is null`(method));
    }

    private static
    void enforceValidMessage(string method, string message)
    {
        enf(message.length, f!`%s: Message cannot be empty`(method));
    }
}

class MailboxException : Exception
{
    mixin basicExceptionCtors;
}
