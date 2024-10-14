import { createContext, PropsWithChildren, useEffect, useState } from "react";

export const SourceFilesContext = createContext<string[] | null>(null);

export const SourceFilesContextProvider = ({ children }: PropsWithChildren) => {
    const [sourceFiles, setSourceFiles] = useState<string[]>([]);

    useEffect(() => {
        const fn = () => {
            fetch("/api/source_files/")
                .then(res => res.json())
                .then(json => setSourceFiles(json));
        };
        fn();
        const interval = setInterval(fn, 2000);
        return () => clearInterval(interval);
    }, []);

    return (
        <SourceFilesContext.Provider
            value={sourceFiles}
        >
            {children}
        </SourceFilesContext.Provider>
    );
};
