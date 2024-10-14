import { createContext, PropsWithChildren, useContext, useEffect, useState } from "react";
import { ScriptNamesContext } from "./ScriptNamesContext";

export interface SelectedScriptNameContextValue {
    selectedScriptName: string;
    setSelectedScriptName: React.Dispatch<React.SetStateAction<string>>;
}

export const SelectedScriptNameContext = createContext<SelectedScriptNameContextValue | null>(null);

export const SelectedScriptNameContextProvider = ({ children }: PropsWithChildren) => {
    const scriptNames = useContext(ScriptNamesContext)!;
    const [selectedScriptName, setSelectedScriptName] = useState<string>("");

    useEffect(() => {
        if (selectedScriptName === "" && scriptNames.length) {
            setSelectedScriptName(scriptNames[0]);
        }
    }, [selectedScriptName, scriptNames]);

    return (
        <SelectedScriptNameContext.Provider
            value={{
                selectedScriptName: selectedScriptName,
                setSelectedScriptName: setSelectedScriptName,
            }}
        >
            {children}
        </SelectedScriptNameContext.Provider>
    );
};
