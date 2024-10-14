import { Editor, useMonaco } from "@monaco-editor/react";
import * as monaco_editor from 'monaco-editor';
import { useContext, useEffect, useState } from "react";
import { SelectedSourceFileContext } from "../contexts/SelectedSourceFileContext";
import { SourceCodeContext } from "../contexts/SourceCodeContext";

const sourceFileModelUri = monaco_editor.Uri.parse("inmemory://sourceFile.lua");
const luaApiFileModelUri = monaco_editor.Uri.parse("inmemory://luaApiFile.lua");

export const SourceFileEditor = () => {
    const { selectedSourceFile } = useContext(SelectedSourceFileContext)!;
    const { sourceCode, setSourceCode } = useContext(SourceCodeContext)!;

    const monaco = useMonaco();
    const [luaApiFileModel, setLuaApiFileModel] = useState<monaco_editor.editor.ITextModel | null>(null);
    const [modelsCreated, setModelsCreated] = useState<boolean>(false);

    // Create models
    useEffect(() => {
        if (monaco && selectedSourceFile.length && sourceCode && !modelsCreated) {
            if (!monaco.editor.getModel(sourceFileModelUri)) {
                monaco.editor.createModel(sourceCode ? sourceCode : "", "lua", sourceFileModelUri);
            }
            if (!monaco.editor.getModel(luaApiFileModelUri)) {
                monaco.editor.createModel("lua_api_file", "lua", luaApiFileModelUri);
            }
            setLuaApiFileModel(monaco.editor.getModel(luaApiFileModelUri));
            setModelsCreated(true);
        }
    }, [monaco, selectedSourceFile, sourceCode]);

    // Set LuaApiFileModel contents
    useEffect(() => {
        if (luaApiFileModel) {
            fetch("/api/lua_api_file")
                .then((res) => res.text())
                .then((text) => luaApiFileModel.setValue(JSON.parse(text)));
        }
    }, [luaApiFileModel]);

    // Connect to language server
    /*
    useEffect(() => {
        if (monaco) {
            console.info("Connecting to language server");
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
            ws.onclose = () => languageClient?.dispose();
            return () => ws.close();
        };
    }, [monaco]);
    */

    const onChange = (value: string | undefined) => {
        if (value) {
            setSourceCode(value);
        }
    };

    if (monaco && selectedSourceFile.length && sourceCode !== null && modelsCreated) {
        return (
            <Editor
                width="85vw"
                height="80vh"
                theme="vs-dark"
                value={sourceCode || ""}
                language="lua"
                path={sourceFileModelUri.toString()}
                onChange={onChange}
            />
        )
    } else {
        return "Select a source file to edit";
    }
}
