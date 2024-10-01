module webserver.webserver;

import webserver.mailbox : Mailbox;

import vibe.http.router : URLRouter;
import vibe.http.server : HTTPListener, HTTPServerOption, HTTPServerSettings, listenHTTP;
import vibe.web.rest : path, registerRestInterface, RestInterfaceSettings;

@safe:

final
class Webserver
{
    private HTTPServerSettings m_httpServerSettings;
    private RestInterfaceSettings m_restApiSettings;
    private RestApi m_restApi;
    private URLRouter m_router;
    private HTTPListener m_listener;

    @disable this(ref typeof(this));

    this(string[] bindAddresses, ushort port)
    {
        m_httpServerSettings = new HTTPServerSettings;
        m_httpServerSettings.port = port;
        m_httpServerSettings.bindAddresses = bindAddresses;
        m_httpServerSettings.options |= HTTPServerOption.reuseAddress;
        m_httpServerSettings.options |= HTTPServerOption.reusePort;

        m_restApiSettings = new RestInterfaceSettings;

        m_router = new URLRouter;
        
        m_router.registerRestInterface(m_restApi, m_restApiSettings);
    }

    ~this()
    {
        m_listener.stopListening;
    }

    void start()
    {
        m_listener = listenHTTP(m_httpServerSettings, m_router);
    }
}

@path("/api")
interface IRestApi
{
    @path("/mailbox.json")
    void putMailbox(string topic, string message);
}

private final
class RestApi : IRestApi
{
    this()
    {
    }

    void putMailbox(string topic, string message)
    {
        Mailbox.putMailbox(topic, message);
    }
}
