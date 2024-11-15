import { createContext, PropsWithChildren, useState } from "react";

export interface NewScriptSourceFileContextValue {
    newScriptSourceFile: string;
    setNewScriptSourceFile: React.Dispatch<React.SetStateAction<string>>;
}

export const NewScriptSourceFileContext = createContext<NewScriptSourceFileContextValue | null>(null);

export const NewScriptSourceFileContextProvider = ({ children }: PropsWithChildren) => {
    const [newScriptSourceFile, setNewScriptSourceFile] = useState<string>("");

    return (
        <NewScriptSourceFileContext.Provider
            value={{
                newScriptSourceFile: newScriptSourceFile,
                setNewScriptSourceFile: setNewScriptSourceFile,
            }}
        >
            {children}
        </NewScriptSourceFileContext.Provider>
    );
};
