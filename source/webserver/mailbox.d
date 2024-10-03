module webserver.mailbox;

import vibe.core.log;

@safe:

final
class Mailbox
{
    private shared static string[string] g_mailbox;

    @disable this();
    @disable this(ref typeof(this));

    static
    void putMailbox(string topic, string message)
    {
        debug (mailbox) logDiagnostic(`putMailbox: topic="%s" message="%s"`, topic, message);
        synchronized
        {
            g_mailbox[topic] = message;
        }
    }
    
    static
    string consumeMailbox(string topic)
    {
        debug (mailbox) logDiagnostic(`consumeMailbox: topic="%s"`, topic);
        if (topic.length)
        {
            synchronized
            {
                if (topic in g_mailbox)
                {
                    string message = g_mailbox[topic];
                    g_mailbox.remove(topic);
                    return message;
                }
            }
        }
        return null;
    }
}
