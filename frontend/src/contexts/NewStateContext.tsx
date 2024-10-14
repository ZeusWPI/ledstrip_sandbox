import { createContext, PropsWithChildren, useState } from "react";

export interface NewStateContextValue {
    newState: string;
    setNewState: React.Dispatch<React.SetStateAction<string>>;
}

export const NewStateContext = createContext<NewStateContextValue | null>(null);

export const NewStateContextProvider = ({ children }: PropsWithChildren) => {
    const [newState, setNewState] = useState<string>("");

    return (
        <NewStateContext.Provider
            value={{
                newState: newState,
                setNewState: setNewState,
            }}
        >
            {children}
        </NewStateContext.Provider>
    );
};
