import { createContext, PropsWithChildren, useState } from "react";
import { Script, scriptInit } from "../types/Script";

export interface NewScriptContextValue {
    newScript: Script;
    setNewScript: React.Dispatch<React.SetStateAction<Script>>;
}

export const NewScriptContext = createContext<NewScriptContextValue | null>(null);

export const NewScriptContextProvider = ({ children }: PropsWithChildren) => {
    const [newScript, setNewScript] = useState<Script>(scriptInit);

    return (
        <NewScriptContext.Provider
            value={{
                newScript: newScript,
                setNewScript: setNewScript,
            }}
        >
            {children}
        </NewScriptContext.Provider>
    );
};
