import { createContext, PropsWithChildren, useEffect, useState } from "react";

export const ScriptInstanceNamesContext = createContext<string[] | null>(null);

export const ScriptInstanceNamesContextProvider = ({ children }: PropsWithChildren) => {
    const [scriptInstanceNames, setScriptInstanceNames] = useState<string[]>([]);

    useEffect(() => {
        const fn = () => {
            fetch("/api/script_instances/")
                .then(res => res.json())
                .then(json => setScriptInstanceNames(json));
        };
        fn();
        const interval = setInterval(fn, 2000);
        return () => clearInterval(interval);
    }, []);

    return (
        <ScriptInstanceNamesContext.Provider
            value={scriptInstanceNames}
        >
            {children}
        </ScriptInstanceNamesContext.Provider>
    );
};
