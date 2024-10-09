import { useState } from "react";
import { Fps } from "./Fps";
import { States } from "./States";

export const App = () => {
    const [states, setStates] = useState<string[]>([]);
    const [activeState, setActiveState] = useState<string>("");

    return (<>
        <h1>Ledstrip</h1>
        <Fps />
        <States
            states={states} setStates={setStates}
            activeState={activeState} setActiveState={setActiveState}
        />
    </>);
};
