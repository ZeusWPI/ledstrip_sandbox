import { createContext, PropsWithChildren, useContext, useEffect, useState } from "react";
import { Script, scriptInit } from "../types/Script";
import { SelectedScriptNameContext } from "./SelectedScriptNameContext";

export const SelectedScriptContext = createContext<Script | null>(null);

export const SelectedScriptContextProvider = ({ children }: PropsWithChildren) => {
    const { selectedScriptName } = useContext(SelectedScriptNameContext)!;
    const [selectedScript, setSelectedScript] = useState<Script>(scriptInit);

    useEffect(() => {
        if (selectedScriptName !== "") {
            const fn = () => {
                fetch(`/api/scripts/${selectedScriptName}/`)
                    .then(res => res.json())
                    .then(json => setSelectedScript(json));
            };
            fn();
            const interval = setInterval(() => fn(), 2000);
            return () => clearInterval(interval);
        }
    }, [selectedScriptName]);

    return (
        <SelectedScriptContext.Provider
            value={selectedScript}
        >
            {children}
        </SelectedScriptContext.Provider>
    );
};
