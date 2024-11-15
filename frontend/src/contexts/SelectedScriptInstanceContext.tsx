import { createContext, PropsWithChildren, useContext, useEffect, useState } from "react";
import { ScriptInstance, scriptInstanceInit } from "../types/ScriptInstance";
import { SelectedScriptInstanceNameContext } from "./SelectedScriptInstanceNameContext";

export const SelectedScriptInstanceContext = createContext<ScriptInstance | null>(null);

export const SelectedScriptInstanceContextProvider = ({ children }: PropsWithChildren) => {
    const { selectedScriptInstanceName } = useContext(SelectedScriptInstanceNameContext)!;
    const [selectedScriptInstance, setSelectedScriptInstance] = useState<ScriptInstance>(scriptInstanceInit);

    useEffect(() => {
        if (selectedScriptInstanceName !== "") {
            const fn = () => {
                fetch(`/api/script_instances/${selectedScriptInstanceName}/`)
                    .then(res => res.json())
                    .then(json => setSelectedScriptInstance(json));
            };
            fn();
            const interval = setInterval(() => fn(), 2000);
            return () => clearInterval(interval);
        }
    }, [selectedScriptInstanceName]);

    return (
        <SelectedScriptInstanceContext.Provider
            value={selectedScriptInstance}
        >
            {children}
        </SelectedScriptInstanceContext.Provider>
    );
};
