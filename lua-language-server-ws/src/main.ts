import { resolve } from 'path';
import { IWebSocket, WebSocketMessageReader, WebSocketMessageWriter } from 'vscode-ws-jsonrpc';
import { createConnection, createServerProcess, forward } from 'vscode-ws-jsonrpc/server';
import { WebSocketServer } from 'ws';

export const launch = (socket: IWebSocket) => {
    const reader = new WebSocketMessageReader(socket);
    const writer = new WebSocketMessageWriter(socket);

    const socketConnection = createConnection(
        reader,
        writer,
        () => socket.dispose(),
    );
    const serverConnection = createServerProcess(
        'Lua Language Server',
        resolve(process.cwd(), './lua-language-server/bin/lua-language-server'),
    )!;
    forward(socketConnection, serverConnection);
};

const wsServer = new WebSocketServer({
    host: "0.0.0.0",
    port: 9999,
});
console.info(`Lua language server listening on ws://${wsServer.options.host}:${wsServer.options.port}`);
wsServer.on("connection", (ws) => {
    const socket: IWebSocket = {
        send: (content) => {
            ws.send(content, (error) => {
                if (error) {
                    throw error;
                }
            });
        },
        onMessage: (callback) => ws.on("message", callback),
        onError: (callback) => ws.on("error", callback),
        onClose: (callback) => ws.on("close", callback),
        dispose: () => ws.close(),
    }
    if (ws.readyState === ws.OPEN) {
        launch(socket);
    } else {
        ws.on("open", () => launch(socket));
    }
});
