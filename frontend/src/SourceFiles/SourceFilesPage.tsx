import { Editor, useMonaco } from "@monaco-editor/react";
import * as monaco_editor from 'monaco-editor';
import { useContext, useEffect } from "react";
import { SourceCodeContext } from "../contexts/SourceCodeContext";

const sourceFileModelUri = monaco_editor.Uri.parse("inmemory://sourceFile.lua");
const luaApiFileModelUri = monaco_editor.Uri.parse("inmemory://luaApiFile.lua");

export const SourceFilesPage = () => {
    const monaco = useMonaco();
    const { sourceCode, setSourceCode } = useContext(SourceCodeContext)!;

    // Create models
    useEffect(() => {
        if (monaco) {
            if (!monaco.editor.getModel(sourceFileModelUri)) {
                monaco.editor.createModel(sourceCode, "lua", sourceFileModelUri);
            }
            if (!monaco.editor.getModel(luaApiFileModelUri)) {
                monaco.editor.createModel("lua_api_file", "lua", luaApiFileModelUri);
            }
            console.log(monaco.editor.getModels());
        }
    }, [monaco]);

    // Set LuaApiFileModel contents
    /*
    useEffect(() => {
        if (luaApiFileModel) {
            console.info("Fetching and setting LuaApiFileModel contents");
            // fetch("/api/lua_api_file")
            //     .then((res) => res.text())
            //     .then((text) => luaApiFileModel.setValue(JSON.parse(text)));
        }
    }, [luaApiFileModel]);
    */

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

    return (
        <Editor
            height="80vh"
            theme="vs-dark"
            value=""
            language="lua"
            path={sourceFileModelUri.toString()}
            onChange={onChange}
        />
    );
};
