import { createContext, PropsWithChildren, useState } from "react";
import { ScriptInstance, scriptInstanceInit } from "../types/ScriptInstance";

export interface NewScriptInstanceContextValue {
    newScriptInstance: ScriptInstance;
    setNewScriptInstance: React.Dispatch<React.SetStateAction<ScriptInstance>>;
}

export const NewScriptInstanceContext = createContext<NewScriptInstanceContextValue | null>(null);

export const NewScriptInstanceContextProvider = ({ children }: PropsWithChildren) => {
    const [newScriptInstance, setNewScriptInstance] = useState<ScriptInstance>(scriptInstanceInit);

    return (
        <NewScriptInstanceContext.Provider
            value={{
                newScriptInstance: newScriptInstance,
                setNewScriptInstance: setNewScriptInstance,
            }}
        >
            {children}
        </NewScriptInstanceContext.Provider>
    );
};
