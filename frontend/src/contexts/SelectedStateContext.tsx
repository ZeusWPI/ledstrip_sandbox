import { createContext, PropsWithChildren, useContext, useEffect, useState } from "react";
import { StatesContext } from "./StatesContext";

export interface SelectedStateContextValue {
    selectedState: string;
    setSelectedState: React.Dispatch<React.SetStateAction<string>>;
}

export const SelectedStateContext = createContext<SelectedStateContextValue | null>(null);

export const SelectedStateContextProvider = ({ children }: PropsWithChildren) => {
    const states = useContext(StatesContext)!;
    const [selectedState, setSelectedState] = useState<string>("");

    useEffect(() => {
        if (selectedState === "" && states.length) {
            setSelectedState(states[0]);
        }
    }, [selectedState, states]);

    return (
        <SelectedStateContext.Provider
            value={{
                selectedState: selectedState,
                setSelectedState: setSelectedState,
            }}
        >
            {children}
        </SelectedStateContext.Provider>
    );
};
