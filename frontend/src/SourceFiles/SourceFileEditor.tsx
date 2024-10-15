import { useContext, useEffect, useState } from "react";
import { SelectedSourceFileContext } from "../contexts/SelectedSourceFileContext";
import { SourceCodeContext } from "../contexts/SourceCodeContext";
import { getExtension } from "../types/Script";

import * as monaco from 'monaco-editor';
import { initServices } from 'monaco-languageclient/vscode/services';
import { LogLevel } from 'vscode/services';
import { MonacoLanguageClient } from 'monaco-languageclient';
import { WebSocketMessageReader, WebSocketMessageWriter, toSocket } from 'vscode-ws-jsonrpc';
import { CloseAction, ErrorAction, MessageTransports } from 'vscode-languageclient/browser.js';
import { ConsoleLogger } from 'monaco-languageclient/tools';

// @ts-ignore
import * as lua_language from "monaco-languages/release/esm/lua/lua.js";

const sourceFileModelUri = monaco.Uri.parse("inmemory://sourceFile.lua");
const luaApiFileModelUri = monaco.Uri.parse("inmemory://luaApiFile");

const logger = new ConsoleLogger(LogLevel.Debug);
const htmlContainer = document.getElementById('monaco-editor-root')!;
await initServices({
    htmlContainer,
    logger,
});

// monaco.languages.register({ id: "bf" });
// monaco.languages.setLanguageConfiguration("bf", {
//     brackets: [
//         ["[", "]"],
//     ],
// });
// monaco.languages.setMonarchTokensProvider("bf", {
//     tokenizer: {
//         root: [
//             [/[><+-.,]/, "operators"],
//             [/[\[\]]/, "@brackets"],
//             [/./, "comment"],
//         ],
//     },
// });

monaco.languages.register({ id: "lua" });
monaco.languages.setLanguageConfiguration("lua", lua_language.conf);
monaco.languages.setMonarchTokensProvider("lua", lua_language.language);

const model = monaco.editor.createModel(
    "for i=0, 10 do print(i) end",
    "lua",
    sourceFileModelUri,
);
monaco.editor.create(htmlContainer, {
    model: model,
    automaticLayout: true,
    wordBasedSuggestions: "off",
    theme: "vs-dark",
});

const ws = new WebSocket("ws://localhost:9999");
ws.onopen = () => {
    const socket = toSocket(ws);
    const reader = new WebSocketMessageReader(socket);
    const writer = new WebSocketMessageWriter(socket);
    const languageClient = new MonacoLanguageClient({
        name: "Lua Language Client",
        clientOptions: {
            documentSelector: ["lua"],
            errorHandler: {
                error: () => ({ action: ErrorAction.Continue }),
                closed: () => ({ action: CloseAction.DoNotRestart }),
            },
        },
        messageTransports: { reader, writer },
    });
    languageClient.start();
    console.log("Language server started");
    reader.onClose(() => languageClient.stop());
};

export const SourceFileEditor = () => {
    // Setup editor
    /*
    useEffect(() => {
        if (monaco && selectedSourceFile.length && sourceCode && !editorInitialized) {
            // Setup language support

            const ws = new WebSocket("ws://localhost:9999");
            let languageClient: MonacoLanguageClient | null = null;
            ws.onopen = () => {
                const socket = toSocket(ws);
                const reader = new WebSocketMessageReader(socket);
                const writer = new WebSocketMessageWriter(socket);
                languageClient = new MonacoLanguageClient({
                    name: "Lua Language Client",
                    clientOptions: {
                        documentSelector: ["lua"],
                        errorHandler: {
                            error: () => ({ action: ErrorAction.Continue }),
                            closed: () => ({ action: CloseAction.DoNotRestart })
                        }
                    },
                    connectionProvider: {
                        get: () => Promise.resolve({ reader, writer }),
                    },
                });
                languageClient.start();
            };

            // Create models
            if (!monaco.editor.getModel(sourceFileModelUri)) {
                monaco.editor.createModel(
                    sourceCode ? sourceCode : "",
                    ext,
                    sourceFileModelUri,
                );
            }
            if (ext === "lua") {
                if (!monaco.editor.getModel(luaApiFileModelUri)) {
                    monaco.editor.createModel(
                        "lua_api_file",
                        "lua",
                        luaApiFileModelUri,
                    );
                }
                setLuaApiFileModel(monaco.editor.getModel(luaApiFileModelUri));
            }

            // Run only once
            setEditorInitialized(true);
            return () => {
                ws.close();
            };
        }
    }, [monaco, selectedSourceFile, sourceCode]);
    */

    // Set LuaApiFileModel contents
    /*
    useEffect(() => {
        if (luaApiFileModel) {
            fetch("/api/lua_api_file")
                .then((res) => res.text())
                .then((text) => luaApiFileModel.setValue(JSON.parse(text)));
        }
    }, [luaApiFileModel]);
    */

    return "Select a source file to edit";
}
