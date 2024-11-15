import { createContext, PropsWithChildren, useContext, useEffect, useState } from "react";
import { SelectedScriptSourceFileContext } from "./SelectedScriptSourceFileContext";

export interface ScriptSourceCodeContextValue {
    scriptSourceCode: string | null;
    setScriptSourceCode: React.Dispatch<React.SetStateAction<string | null>>;
}

export const ScriptSourceCodeContext = createContext<ScriptSourceCodeContextValue | null>(null);

export const ScriptSourceCodeContextProvider = ({ children }: PropsWithChildren) => {
    const { selectedScriptSourceFile: selectedScriptSourceFile } = useContext(SelectedScriptSourceFileContext)!;
    const [scriptSourceCode, setScriptSourceCode] = useState<string | null>(null);

    useEffect(() => {
        if (selectedScriptSourceFile.length) {
            fetch(`/api/script_source_files/${selectedScriptSourceFile}/`)
                .then(res => res.json())
                .then(json => setScriptSourceCode(json.sourceCode));
        }
    }, [selectedScriptSourceFile]);

    return (
        <ScriptSourceCodeContext.Provider
            value={{
                scriptSourceCode: scriptSourceCode,
                setScriptSourceCode: setScriptSourceCode,
            }}
        >
            {children}
        </ScriptSourceCodeContext.Provider>
    );
};
