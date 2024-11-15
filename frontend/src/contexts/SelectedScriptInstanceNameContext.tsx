import { createContext, PropsWithChildren, useContext, useEffect, useState } from "react";
import { ScriptInstanceNamesContext } from "./ScriptInstanceNamesContext";

export interface SelectedScriptInstanceNameContextValue {
    selectedScriptInstanceName: string;
    setSelectedScriptInstanceName: React.Dispatch<React.SetStateAction<string>>;
}

export const SelectedScriptInstanceNameContext = createContext<SelectedScriptInstanceNameContextValue | null>(null);

export const SelectedScriptInstanceNameContextProvider = ({ children }: PropsWithChildren) => {
    const scriptInstanceNames = useContext(ScriptInstanceNamesContext)!;
    const [selectedScriptInstanceName, setSelectedScriptInstanceName] = useState<string>("");

    useEffect(() => {
        if (selectedScriptInstanceName === "" && scriptInstanceNames.length) {
            setSelectedScriptInstanceName(scriptInstanceNames[0]);
        }
    }, [selectedScriptInstanceName, scriptInstanceNames]);

    return (
        <SelectedScriptInstanceNameContext.Provider
            value={{
                selectedScriptInstanceName: selectedScriptInstanceName,
                setSelectedScriptInstanceName: setSelectedScriptInstanceName,
            }}
        >
            {children}
        </SelectedScriptInstanceNameContext.Provider>
    );
};
