import { createContext, PropsWithChildren, useEffect, useState } from "react";

export const StatesContext = createContext<string[] | null>(null);

export const StatesContextProvider = ({ children }: PropsWithChildren) => {
    const [states, setStates] = useState<string[]>([]);

    useEffect(() => {
        const fn = () => {
            fetch("/api/states/")
                .then(res => res.json())
                .then(json => setStates(json));
        };
        fn();
        const interval = setInterval(fn, 500);
        return () => clearInterval(interval);
    }, []);

    return (
        <StatesContext.Provider
            value={states}
        >
            {children}
        </StatesContext.Provider>
    );
};
