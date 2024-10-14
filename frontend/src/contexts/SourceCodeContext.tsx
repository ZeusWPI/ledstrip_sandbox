import { createContext, PropsWithChildren, useState } from "react";

export interface SourceCodeContextValue {
    sourceCode: string;
    setSourceCode: React.Dispatch<React.SetStateAction<string>>;
}

export const SourceCodeContext = createContext<SourceCodeContextValue | null>(null);

export const SourceCodeContextProvider = ({ children }: PropsWithChildren) => {
    const [sourceCode, setSourceCode] = useState<string>("");

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