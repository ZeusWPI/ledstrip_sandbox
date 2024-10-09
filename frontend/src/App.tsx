import { useState } from "react";
import { Fps } from "./Fps";
import { States } from "./States";
import { Segments } from "./Segments";

export const App = () => {
    const [states, setStates] = useState<string[]>([]);
    const [activeState, setActiveState] = useState<string>("");
    const [selectedState, setSelectedState] = useState<string>("");

    return (<>
        <h1>Ledstrip</h1>
        <h3>Config</h3>
        <Fps />
        <h3>States</h3>
        <States
            states={states} setStates={setStates}
            activeState={activeState} setActiveState={setActiveState}
            selectedState={selectedState} setSelectedState={setSelectedState}
        />
        <h3>Segments in state "{selectedState}"</h3>
        <Segments
            selectedState={selectedState}
        />
    </>);
};
