import { createContext, PropsWithChildren, useState } from "react";

export interface NewSourceFileContextValue {
    newSourceFile: string;
    setNewSourceFile: React.Dispatch<React.SetStateAction<string>>;
}

export const NewSourceFileContext = createContext<NewSourceFileContextValue | null>(null);

export const NewSourceFileContextProvider = ({ children }: PropsWithChildren) => {
    const [newSourceFile, setNewSourceFile] = useState<string>("");

    return (
        <NewSourceFileContext.Provider
            value={{
                newSourceFile: newSourceFile,
                setNewSourceFile: setNewSourceFile,
            }}
        >
            {children}
        </NewSourceFileContext.Provider>
    );
};
