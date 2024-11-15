import { createContext, PropsWithChildren, useContext, useEffect, useState } from "react";
import { SelectedScriptInstanceNameContext } from "./SelectedScriptInstanceNameContext";

export const SelectedScriptInstanceRunningContext = createContext<boolean | null>(null);

export const SelectedScriptInstanceRunningContextProvider = ({ children }: PropsWithChildren) => {
    const { selectedScriptInstanceName } = useContext(SelectedScriptInstanceNameContext)!;
    const [selectedScriptInstanceRunning, setSelectedScriptInstanceRunning] = useState<boolean>(false);

    useEffect(() => {
        if (selectedScriptInstanceName !== "") {
            const fn = () => {
                fetch(`/api/script_instances/${selectedScriptInstanceName}/running`)
                    .then(res => res.text())
                    .then(text => setSelectedScriptInstanceRunning(JSON.parse(text)));
            };
            fn();
            const interval = setInterval(() => fn(), 2000);
            return () => clearInterval(interval);
        }
    }, [selectedScriptInstanceName]);

    return (
        <SelectedScriptInstanceRunningContext.Provider
            value={selectedScriptInstanceRunning}
        >
            {children}
        </SelectedScriptInstanceRunningContext.Provider>
    );
};
