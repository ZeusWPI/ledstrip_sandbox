import { useEffect, useState } from "react";

import "./States.css";

export interface StatesProps {
    states: string[];
    setStates: React.Dispatch<React.SetStateAction<string[]>>;
    activeState: string;
    setActiveState: React.Dispatch<React.SetStateAction<string>>;
};

export const States = ({ states, setStates, activeState, setActiveState }: StatesProps) => {
    const [selectedState, setSelectedState] = useState<string>("");

    const fetchStates = () => {
        fetch("/api/states/")
            .then(res => res.json())
            .then(json => setStates(json));
        fetch("/api/active_state")
            .then(res => res.text())
            .then(text => setActiveState(JSON.parse(text)));
    };

    const activate = (state: string) => {
        fetch(`/api/states/${state}/activate`, {
            method: "POST",
        }).then(() => setActiveState(state));
    };

    useEffect(() => {
        fetchStates();
        setInterval(fetchStates, 500);
    }, [setStates, setActiveState]);

    useEffect(() => {
        if (selectedState === "" && states.length) {
            setSelectedState(states[0]);
        }
    }, [states, selectedState, setSelectedState]);

    const options = states.map((s) => {
        let classes = "";
        if (s === activeState) {
            classes += "activeState";
        }
        return <option className={classes} key={s} value={s}>{s}</option>
    });

    return <table><tbody><tr>
        <td>
            <select
                size={options.length}
                onChange={(e) => setSelectedState(states[e.target.selectedIndex])}
            >
                {options}
            </select>
        </td>
        <td>
            <p>Selected: {selectedState}</p>
            <p>
                {selectedState === activeState && "This is the active state" || "Not the active state"}
                <input
                    className="inline"
                    type="button"
                    value="Activate"
                    disabled={selectedState === activeState}
                    onClick={() => activate(selectedState)}
                />
            </p>
        </td>
    </tr></tbody></table>;
};
