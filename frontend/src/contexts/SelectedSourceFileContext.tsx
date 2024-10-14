import { createContext, PropsWithChildren, useState } from "react";

export interface SelectedSourceFileContextValue {
    selectedSourceFile: string;
    setSelectedSourceFile: React.Dispatch<React.SetStateAction<string>>;
}

export const SelectedSourceFileContext = createContext<SelectedSourceFileContextValue | null>(null);

export const SelectedSourceFileContextProvider = ({ children }: PropsWithChildren) => {
    const [selectedSourceFile, setSelectedSourceFile] = useState<string>("");

    return (
        <SelectedSourceFileContext.Provider
            value={{
                selectedSourceFile: selectedSourceFile,
                setSelectedSourceFile: setSelectedSourceFile,
            }}
        >
            {children}
        </SelectedSourceFileContext.Provider>
    );
};
