import * as monaco from 'monaco-editor';
import { useWorkerFactory } from 'monaco-editor-wrapper/workerFactory';
import { MonacoLanguageClient } from 'monaco-languageclient';
import { ConsoleLogger } from 'monaco-languageclient/tools';
import { initServices } from 'monaco-languageclient/vscode/services';
import { useContext, useEffect, useMemo, useRef, useState } from "react";
import { CloseAction, ErrorAction } from 'vscode-languageclient/browser.js';
import { toSocket, WebSocketMessageReader, WebSocketMessageWriter } from 'vscode-ws-jsonrpc';
import { LogLevel } from 'vscode/services';
import { SelectedScriptSourceFileContext } from "../contexts/SelectedScriptSourceFileContext";
import { ScriptSourceCodeContext } from "../contexts/ScriptSourceCodeContext";
import { getExtension } from "../types/ScriptInstance";

// @ts-ignore
import * as lua_language from "monaco-languages/release/esm/lua/lua.js";
// @ts-ignore
import * as python_language from "monaco-languages/release/esm/python/python.js";
import { ScriptSourceCodeModifiedContext } from '../contexts/ScriptSourceCodeModifiedContext';

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

    monaco.languages.register({ id: "py" });
    monaco.languages.setLanguageConfiguration("py", python_language.conf);
    monaco.languages.setMonarchTokensProvider("py", python_language.language);

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

const scriptSourceFileModelUri = monaco.Uri.parse("inmemory://scriptSourceFile");
const apiFileModelUri = monaco.Uri.parse("inmemory://apiFile");

export const ScriptSourceFileEditor = () => {
    const editorElementRef = useRef<HTMLDivElement | null>(null);
    const { selectedScriptSourceFile } = useContext(SelectedScriptSourceFileContext)!;
    const { scriptSourceCode, setScriptSourceCode } = useContext(ScriptSourceCodeContext)!;
    const { setScriptSourceCodeModified } = useContext(ScriptSourceCodeModifiedContext)!;
    const [initialized, setInitialized] = useState<boolean>(false);

    const ext = useMemo<string>(() => getExtension(selectedScriptSourceFile), [selectedScriptSourceFile]);

    // Create models and editor
    useEffect(() => {
        if (editorElementRef.current && selectedScriptSourceFile && scriptSourceCode !== null && !initialized) {
            setInitialized(true);

            monaco.editor.createModel(scriptSourceCode, ext, scriptSourceFileModelUri);
            monaco.editor.createModel("", ext, apiFileModelUri);

            monaco.editor.getModel(scriptSourceFileModelUri)!.onDidChangeContent(() => {
                setScriptSourceCode(monaco.editor.getModel(scriptSourceFileModelUri)!.getValue());
                setScriptSourceCodeModified(true);
            });

            monaco.editor.create(editorElementRef.current, {
                model: monaco.editor.getModel(scriptSourceFileModelUri)!,
                automaticLayout: true,
                theme: "vs-dark",
            });
        }
    }, [editorElementRef, selectedScriptSourceFile, scriptSourceCode]);

    // Set apiFileModel contents
    // useEffect(() => {
    //     if (initialized) {
    //         if (ext == "lua") {
    //             fetch("/api/lua_api_file")
    //                 .then((res) => res.text())
    //                 .then((text) => monaco.editor.getModel(apiFileModelUri)!.setValue(JSON.parse(text)));
    //         }
    //     }
    // }, [initialized]);

    // Cleanup
    useEffect(() => {
        return () => {
            monaco.editor.getEditors().forEach(editor => editor.dispose());
            monaco.editor.getModels().forEach(model => model.dispose());
            setInitialized(false);
        };
    }, [selectedScriptSourceFile]);

    return <>
        <div ref={editorElementRef} style={{ width: "80vw", height: "70vh" }}>
        </div>
    </>;
}
