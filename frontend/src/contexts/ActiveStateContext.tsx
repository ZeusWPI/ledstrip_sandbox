import { createContext, PropsWithChildren, useEffect, useState } from "react";

export const ActiveStateContext = createContext<string | null>(null);

export const ActiveStateContextProvider = ({ children }: PropsWithChildren) => {
    const [activeState, setActiveState] = useState<string>("");

    useEffect(() => {
        const fn = () => {
            fetch("/api/active_state")
                .then(res => res.text())
                .then(text => setActiveState(JSON.parse(text)));
        };
        fn();
        const interval = setInterval(fn, 2000);
        return () => clearInterval(interval);
    }, []);

    return (
        <ActiveStateContext.Provider
            value={activeState}
        >
            {children}
        </ActiveStateContext.Provider>
    );
};