import { createContext, PropsWithChildren, useContext, useEffect, useState } from "react";
import { SelectedScriptNameContext } from "./SelectedScriptNameContext";

export const SelectedScriptRunningContext = createContext<boolean | null>(null);

export const SelectedScriptRunningContextProvider = ({ children }: PropsWithChildren) => {
    const { selectedScriptName } = useContext(SelectedScriptNameContext)!;
    const [selectedScriptRunning, setSelectedScriptRunning] = useState<boolean>(false);

    useEffect(() => {
        if (selectedScriptName !== "") {
            const fn = () => {
                fetch(`/api/scripts/${selectedScriptName}/running`)
                    .then(res => res.text())
                    .then(text => setSelectedScriptRunning(JSON.parse(text)));
            };
            fn();
            const interval = setInterval(() => fn(), 2000);
            return () => clearInterval(interval);
        }
    }, [selectedScriptName]);

    return (
        <SelectedScriptRunningContext.Provider
            value={selectedScriptRunning}
        >
            {children}
        </SelectedScriptRunningContext.Provider>
    );
};
