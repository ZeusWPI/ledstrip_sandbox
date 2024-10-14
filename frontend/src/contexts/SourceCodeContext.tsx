import { createContext, PropsWithChildren, useContext, useEffect, useState } from "react";
import { SelectedSourceFileContext } from "./SelectedSourceFileContext";

export interface SourceCodeContextValue {
    sourceCode: string | null;
    setSourceCode: React.Dispatch<React.SetStateAction<string | null>>;
}

export const SourceCodeContext = createContext<SourceCodeContextValue | null>(null);

export const SourceCodeContextProvider = ({ children }: PropsWithChildren) => {
    const { selectedSourceFile } = useContext(SelectedSourceFileContext)!;
    const [sourceCode, setSourceCode] = useState<string | null>(null);

    useEffect(() => {
        if (selectedSourceFile.length) {
            fetch(`/api/source_files/${selectedSourceFile}/`)
                .then(res => res.json())
                .then(json => setSourceCode(json.sourceCode));
        }
    }, [selectedSourceFile]);

    return (
        <SourceCodeContext.Provider
            value={{
                sourceCode: sourceCode,
                setSourceCode: setSourceCode,
            }}
        >
            {children}
        </SourceCodeContext.Provider>
    );
};