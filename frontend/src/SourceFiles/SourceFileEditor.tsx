import * as monaco from 'monaco-editor';
import { useWorkerFactory } from 'monaco-editor-wrapper/workerFactory';
import { MonacoLanguageClient } from 'monaco-languageclient';
import { ConsoleLogger } from 'monaco-languageclient/tools';
import { initServices } from 'monaco-languageclient/vscode/services';
import { useContext, useEffect, useMemo, useRef, useState } from "react";
import { CloseAction, ErrorAction } from 'vscode-languageclient/browser.js';
import { toSocket, WebSocketMessageReader, WebSocketMessageWriter } from 'vscode-ws-jsonrpc';
import { LogLevel } from 'vscode/services';
import { SelectedSourceFileContext } from "../contexts/SelectedSourceFileContext";
import { SourceCodeContext } from "../contexts/SourceCodeContext";
import { getExtension } from "../types/Script";

// @ts-ignore
import * as lua_language from "monaco-languages/release/esm/lua/lua.js";

let initMonacoCalled = false;
const initMonaco = async () => {
    if (initMonacoCalled)
        return;
    initMonacoCalled = true;

    // @ts-ignore
    await initServices({
        logger: new ConsoleLogger(LogLevel.Warning),
    });

    monaco.languages.register({ id: "bf" });
    monaco.languages.setLanguageConfiguration("bf", {
        brackets: [["[", "]"]],
    });
    monaco.languages.setMonarchTokensProvider("bf", {
        tokenizer: {
            root: [
                [/[><+-.,[\]]/, "operator"],
                [/./, "comment"],
            ],
        },
    });

    monaco.languages.register({ id: "lua" });
    monaco.languages.setLanguageConfiguration("lua", lua_language.conf);
    monaco.languages.setMonarchTokensProvider("lua", lua_language.language);

    const luaLanguageClientWs = new WebSocket(`ws://${window.location.hostname}:9999`);
    let luaLanguageClient = null;
    luaLanguageClientWs.onopen = () => {
        const socket = toSocket(luaLanguageClientWs);
        const reader = new WebSocketMessageReader(socket);
        const writer = new WebSocketMessageWriter(socket);
        luaLanguageClient = new MonacoLanguageClient({
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
        luaLanguageClient.start();
    };

    useWorkerFactory({});
};
await initMonaco();

const sourceFileModelUri = monaco.Uri.parse("inmemory://sourceFile");
const apiFileModelUri = monaco.Uri.parse("inmemory://apiFile");

export const SourceFileEditor = () => {
    const editorElementRef = useRef<HTMLDivElement | null>(null);
    const { selectedSourceFile } = useContext(SelectedSourceFileContext)!;
    const { sourceCode, setSourceCode } = useContext(SourceCodeContext)!;
    const [initialized, setInitialized] = useState<boolean>(false);

    const ext = useMemo<string>(() => getExtension(selectedSourceFile), [selectedSourceFile]);

    // Create models and editor
    useEffect(() => {
        if (editorElementRef.current && selectedSourceFile && sourceCode !== null && !initialized) {
            setInitialized(true);

            monaco.editor.createModel(sourceCode, ext, sourceFileModelUri);
            monaco.editor.createModel("", ext, apiFileModelUri);

            monaco.editor.getModel(sourceFileModelUri)!.onDidChangeContent(() => {
                setSourceCode(monaco.editor.getModel(sourceFileModelUri)!.getValue());
            });

            monaco.editor.create(editorElementRef.current, {
                model: monaco.editor.getModel(sourceFileModelUri)!,
                automaticLayout: true,
                theme: "vs-dark",
            });
        }
    }, [editorElementRef, selectedSourceFile, sourceCode]);

    // Set apiFileModel contents
    useEffect(() => {
        if (initialized) {
            if (ext == "lua") {
                fetch("/api/lua_api_file")
                    .then((res) => res.text())
                    .then((text) => monaco.editor.getModel(apiFileModelUri)!.setValue(JSON.parse(text)));
            }
        }
    }, [initialized]);

    // Cleanup
    useEffect(() => {
        return () => {
            monaco.editor.getEditors().forEach(editor => editor.dispose());
            monaco.editor.getModels().forEach(model => model.dispose());
        };
    }, []);

    return <>
        <div ref={editorElementRef} style={{ width: "80vw", height: "70vh" }}>
        </div>
    </>;
}
