import { createContext, PropsWithChildren, useState } from "react";

export interface SelectedScriptSourceFileContextValue {
    selectedScriptSourceFile: string;
    setSelectedScriptSourceFile: React.Dispatch<React.SetStateAction<string>>;
}

export const SelectedScriptSourceFileContext = createContext<SelectedScriptSourceFileContextValue | null>(null);

export const SelectedScriptSourceFileContextProvider = ({ children }: PropsWithChildren) => {
    const [selectedScriptSourceFile, setScriptSelectedSourceFile] = useState<string>("");

    return (
        <SelectedScriptSourceFileContext.Provider
            value={{
                selectedScriptSourceFile: selectedScriptSourceFile,
                setSelectedScriptSourceFile: setScriptSelectedSourceFile,
            }}
        >
            {children}
        </SelectedScriptSourceFileContext.Provider>
    );
};
