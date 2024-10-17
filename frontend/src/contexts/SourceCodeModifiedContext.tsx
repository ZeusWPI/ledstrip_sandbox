import { createContext, PropsWithChildren, useContext, useEffect, useState } from "react";
import { SelectedSourceFileContext } from "./SelectedSourceFileContext";

export interface SourceCodeModifiedContextValue {
    sourceCodeModified: boolean;
    setSourceCodeModified: React.Dispatch<React.SetStateAction<boolean>>;
}

export const SourceCodeModifiedContext = createContext<SourceCodeModifiedContextValue | null>(null);

export const SourceCodeModifiedContextProvider = ({ children }: PropsWithChildren) => {
    const { selectedSourceFile } = useContext(SelectedSourceFileContext)!;
    const [sourceCodeModified, setSourceCodeModified] = useState<boolean>(false);

    useEffect(() => {
        if (selectedSourceFile.length) {
            setSourceCodeModified(false);
        }
    }, [selectedSourceFile]);

    return (
        <SourceCodeModifiedContext.Provider
            value={{
                sourceCodeModified: sourceCodeModified,
                setSourceCodeModified: setSourceCodeModified,
            }}
        >
            {children}
        </SourceCodeModifiedContext.Provider>
    );
};
