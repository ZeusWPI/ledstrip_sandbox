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
    const [newState, setNewState] = useState<string>("");

    const fetchStates = () => {
        fetch("/api/states/")
            .then(res => res.json())
            .then(json => setStates(json));
        fetch("/api/active_state")
            .then(res => res.text())
            .then(text => setActiveState(JSON.parse(text)));
    };

    const addState = (state: string) => {
        fetch(`/api/states/${state}/`, {
            method: "POST",
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ "state": newState }),
        });
    };

    const removeState = (state: string) => {
        fetch(`/api/states/${state}/`, {
            method: "DELETE",
        });
    };

    const activateState = (state: string) => {
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

    return <>
        <table><tbody><tr>
            <td>
                <select
                    size={options.length}
                    onChange={(e) => setSelectedState(states[e.target.selectedIndex])}
                >
                    {options}
                </select>
            </td>
            <td>
                Selected: {selectedState}
                <br />
                <br />
                {selectedState === activeState && "This is the active state" || "Not the active state"}
                <input
                    className="inline"
                    type="button"
                    value="Activate"
                    disabled={selectedState === activeState}
                    onClick={() => activateState(selectedState)}
                />
                <br />
                Can only remove states without segments
                <input
                    className="inline"
                    type="button"
                    value="Remove state"
                    onClick={() => removeState(selectedState)}
                />
            </td>
        </tr></tbody></table>
        <input
            className="inline"
            type="text"
            placeholder="State name"
            value={newState}
            onChange={(e) => setNewState(e.target.value)}
        />
        <input
            className="inline"
            type="button"
            value="Add state"
            onClick={() => addState(newState)}
        />
    </>;
};
