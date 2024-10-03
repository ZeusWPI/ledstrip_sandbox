module webserver.webserver;

import ledstrip.led_assignments : LedAssignments, Segment;
import ledstrip.led_positions : getKelderLedPositions, LedPositions;
import main : Main;
import webserver.mailbox : Mailbox;
import webserver.rest_api;
import webserver.rest_api_impl;

import vibe.http.router : URLRouter;
import vibe.http.server : HTTPListener, HTTPServerOption, HTTPServerRequest,
    HTTPServerResponse, HTTPServerSettings, listenHTTP, render;
import vibe.data.json;
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

        m_restApi = new RestApiImpl;

        m_router = new URLRouter;
        m_router.get("/", &handleRequest);
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

    private static
    void handleRequest(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        const LedPositions ledPositions = getKelderLedPositions;

        res.headers["Content-Type"] = "text/html";
        res.render!("editor.dt", ledPositions);
    }
}


