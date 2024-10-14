module webserver.webserver;

import data_dir : DataDir;
import singleton : threadLocalSingleton;
import thread_manager : ThreadManager;

import webserver.mailbox : Mailbox;
import webserver.rest_api;
import webserver.rest_api_impl;

import vibe.data.json;
import vibe.http.fileserver : HTTPFileServerSettings, serveStaticFiles, serveStaticFile;
import vibe.http.router : URLRouter;
import vibe.http.server : HTTPListener, HTTPServerOption, HTTPServerRequest, HTTPServerRequestDelegateS,
    HTTPServerResponse, HTTPServerSettings, listenHTTP, staticRedirect;
import vibe.web.rest : path, registerRestInterface, RestInterfaceSettings;

@safe:

final
class Webserver
{
    mixin threadLocalSingleton;

    private HTTPServerSettings m_httpServerSettings;
    private RestInterfaceSettings m_restApiSettings;
    private RestApi m_restApi;
    private HTTPFileServerSettings m_fileServerSettings;
    private HTTPServerRequestDelegateS m_fileServer;
    private HTTPServerRequestDelegateS m_indexFileServer;
    private URLRouter m_router;
    private HTTPListener m_listener;

    this()
    in (ThreadManager.constInstance.inMainThread)
    {
        m_httpServerSettings = new HTTPServerSettings;
        m_httpServerSettings.port = DataDir.sharedConfig.httpPort;
        m_httpServerSettings.bindAddresses = DataDir.sharedConfig.httpBindAddresses.idup.dup;
        m_httpServerSettings.options |= HTTPServerOption.reuseAddress;
        m_httpServerSettings.options |= HTTPServerOption.reusePort;

        m_restApiSettings = new RestInterfaceSettings;
        m_restApi = new RestApiImpl;

        m_fileServerSettings = new HTTPFileServerSettings();
        m_fileServer = serveStaticFiles("public", m_fileServerSettings);
        m_indexFileServer = serveStaticFile("public/index.html", m_fileServerSettings);

        m_router = new URLRouter;
        m_router.registerRestInterface(m_restApi, m_restApiSettings);
        m_router.get("/", m_indexFileServer);
        m_router.get("/statesSegments", m_indexFileServer);
        m_router.get("/scripts", m_indexFileServer);
        m_router.get("/sourceFiles", m_indexFileServer);
        m_router.get("/config", m_indexFileServer);
        m_router.get("*", m_fileServer);
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
