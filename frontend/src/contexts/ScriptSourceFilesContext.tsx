import { createContext, PropsWithChildren, useEffect, useState } from "react";

export const ScriptSourceFilesContext = createContext<string[] | null>(null);

export const ScriptSourceFilesContextProvider = ({ children }: PropsWithChildren) => {
    const [scriptSourceFiles, setScriptSourceFiles] = useState<string[]>([]);

    useEffect(() => {
        const fn = () => {
            fetch("/api/script_source_files/")
                .then(res => res.json())
                .then(json => setScriptSourceFiles(json));
        };
        fn();
        const interval = setInterval(fn, 2000);
        return () => clearInterval(interval);
    }, []);

    return (
        <ScriptSourceFilesContext.Provider
            value={scriptSourceFiles}
        >
            {children}
        </ScriptSourceFilesContext.Provider>
    );
};
