import { createContext, PropsWithChildren, useContext, useEffect, useState } from "react";
import { SelectedScriptSourceFileContext } from "./SelectedScriptSourceFileContext";

export interface ScriptSourceCodeModifiedContextValue {
    scriptSourceCodeModified: boolean;
    setScriptSourceCodeModified: React.Dispatch<React.SetStateAction<boolean>>;
}

export const ScriptSourceCodeModifiedContext = createContext<ScriptSourceCodeModifiedContextValue | null>(null);

export const ScriptSourceCodeModifiedContextProvider = ({ children }: PropsWithChildren) => {
    const { selectedScriptSourceFile } = useContext(SelectedScriptSourceFileContext)!;
    const [scriptSourceCodeModified, setScriptSourceCodeModified] = useState<boolean>(false);

    useEffect(() => {
        if (selectedScriptSourceFile.length) {
            setScriptSourceCodeModified(false);
        }
    }, [selectedScriptSourceFile]);

    return (
        <ScriptSourceCodeModifiedContext.Provider
            value={{
                scriptSourceCodeModified: scriptSourceCodeModified,
                setScriptSourceCodeModified: setScriptSourceCodeModified,
            }}
        >
            {children}
        </ScriptSourceCodeModifiedContext.Provider>
    );
};
