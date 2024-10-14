import { createContext, PropsWithChildren, useEffect, useState } from "react";

export const ScriptNamesContext = createContext<string[] | null>(null);

export const ScriptNamesContextProvider = ({ children }: PropsWithChildren) => {
    const [scriptNames, setScriptNames] = useState<string[]>([]);

    useEffect(() => {
        const fn = () => {
            fetch("/api/scripts/")
                .then(res => res.json())
                .then(json => setScriptNames(json));
        };
        fn();
        const interval = setInterval(fn, 2000);
        return () => clearInterval(interval);
    }, []);

    return (
        <ScriptNamesContext.Provider
            value={scriptNames}
        >
            {children}
        </ScriptNamesContext.Provider>
    );
};
