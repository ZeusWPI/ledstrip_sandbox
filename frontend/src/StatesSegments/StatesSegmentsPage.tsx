import { useState } from "react";
import { Segments } from "./Segments";
import { States } from "./States";

export const StatesSegmentsPage = () => {
    const [states, setStates] = useState<string[]>([]);
    const [activeState, setActiveState] = useState<string>("");
    const [selectedState, setSelectedState] = useState<string>("");

    return <>
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
    </>
};
