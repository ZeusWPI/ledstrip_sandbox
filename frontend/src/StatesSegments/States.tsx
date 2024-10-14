import { useContext } from "react";
import { ActiveStateContext } from "../contexts/ActiveStateContext";
import { NewStateContext } from "../contexts/NewStateContext";
import { SelectedStateContext } from "../contexts/SelectedStateContext";
import { StatesContext } from "../contexts/StatesContext";

import "./States.css";

export const States = () => {
    const states = useContext(StatesContext)!;
    const activeState = useContext(ActiveStateContext)!;
    const { selectedState, setSelectedState } = useContext(SelectedStateContext)!;
    const { newState, setNewState } = useContext(NewStateContext)!;

    const addState = (state: string) => {
        fetch(`/api/states/${state}/`, {
            method: "POST",
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ "state": state }),
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
        });
    };

    const options = states.map((state) => {
        let classes = "";
        if (state === activeState) {
            classes += "activeState";
        }
        return <option className={classes} key={state} value={state}>{state}</option>
    });

    return <div>
        <table><tbody><tr>
            <td>
                <select
                    size={Math.max(2, states.length + 1)}
                    onChange={(e) => setSelectedState(states[e.target.selectedIndex])}
                    defaultValue={selectedState}
                >
                    {options}
                </select>
            </td>
            <td>
                Selected: "{selectedState}"
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
            defaultValue={newState}
            onChange={(e) => setNewState(e.target.value)}
        />
        <input
            className="inline"
            type="button"
            value="Add state"
            onClick={() => addState(newState)}
        />
    </div>;
};
