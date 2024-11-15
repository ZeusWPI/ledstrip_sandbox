import { useContext } from "react";
import { NewScriptInstanceContext } from "../contexts/NewScriptInstanceContext";
import { ScriptInstanceNamesContext } from "../contexts/ScriptInstanceNamesContext";
import { SelectedScriptInstanceContext } from "../contexts/SelectedScriptInstanceContext";
import { SelectedScriptInstanceNameContext } from "../contexts/SelectedScriptInstanceNameContext";
import { SelectedScriptInstanceRunningContext } from "../contexts/SelectedScriptInstanceRunningContext";
import { ScriptInstance } from "../types/ScriptInstance";

import "./ScriptInstances.css";

export const ScriptInstances = () => {
    const scriptInstanceNames = useContext(ScriptInstanceNamesContext)!;
    const { selectedScriptInstanceName, setSelectedScriptInstanceName } = useContext(SelectedScriptInstanceNameContext)!;
    const selectedScriptInstance = useContext(SelectedScriptInstanceContext)!;
    const selectedScriptInstanceRunning = useContext(SelectedScriptInstanceRunningContext)!;
    const { newScriptInstance, setNewScriptInstance } = useContext(NewScriptInstanceContext)!;

    const addScriptInstance = (scriptInstance: ScriptInstance) => {
        fetch(`/api/script_instances/`, {
            method: "POST",
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ "scriptInstance": scriptInstance }),
        });
    };

    const removeScriptInstance = (name: string) => {
        fetch(`/api/script_instances/${name}/`, {
            method: "DELETE",
        });
    };

    const startScriptInstance = (name: string) => {
        fetch(`/api/script_instances/${name}/start`, {
            method: "POST",
        });
    };

    const stopScriptInstance = (name: string) => {
        fetch(`/api/script_instances/${name}/stop`, {
            method: "POST",
        });
    };

    const reloadScriptInstance = (name: string) => {
        fetch(`/api/script_instances/${name}/reload`, {
            method: "POST",
        });
    };

    return <div>
        <table><tbody><tr>
            <td>
                <select
                    size={Math.max(2, scriptInstanceNames.length + 1)}
                    onChange={(e) => setSelectedScriptInstanceName(scriptInstanceNames[e.target.selectedIndex])}
                    defaultValue={selectedScriptInstanceName}
                >
                    {scriptInstanceNames.sort().map(name => <option key={name} value={name}>{name}</option>)}
                </select>
            </td>
            <td>
                Selected: "{selectedScriptInstanceName}"
                <table style={{ marginLeft: "8px" }}><tbody>
                    <tr><td>File name:</td><td>{selectedScriptInstance.sourceFileName}</td></tr>
                    <tr><td>Led count:</td><td>{selectedScriptInstance.ledCount}</td></tr>
                    <tr><td>Auto start:</td><td>{selectedScriptInstance.autoStart && "true" || "false"}</td></tr>
                    <tr><td>Running:</td><td>{selectedScriptInstanceRunning && "true" || "false"}</td></tr>
                </tbody></table>
                <input
                    className="inline"
                    type="button"
                    value="Start script instance"
                    disabled={selectedScriptInstanceRunning}
                    onClick={() => startScriptInstance(selectedScriptInstanceName)}
                />
                <input
                    className="inline"
                    type="button"
                    value="Stop script instance"
                    disabled={!selectedScriptInstanceRunning}
                    onClick={() => stopScriptInstance(selectedScriptInstanceName)}
                />
                <input
                    className="inline"
                    type="button"
                    value="Reload script instance"
                    disabled={selectedScriptInstanceRunning}
                    onClick={() => reloadScriptInstance(selectedScriptInstanceName)}
                />
                <input
                    className="inline"
                    type="button"
                    value="Remove script instance"
                    disabled={selectedScriptInstanceRunning}
                    onClick={() => removeScriptInstance(selectedScriptInstanceName)}
                />
            </td>
        </tr></tbody></table>
        Name:
        <input
            className="inline"
            type="text"
            defaultValue={newScriptInstance.name}
            onChange={(e) => {
                if (e.target.value.length) {
                    let scriptInstance = newScriptInstance;
                    scriptInstance.name = e.target.value;
                    setNewScriptInstance(scriptInstance);
                }
            }}
        />
        File name:
        <input
            className="inline"
            type="text"
            defaultValue={newScriptInstance.sourceFileName}
            onChange={(e) => {
                if (e.target.value.length) {
                    let scriptInstance = newScriptInstance;
                    scriptInstance.sourceFileName = e.target.value;
                    setNewScriptInstance(scriptInstance);
                }
            }}
        />
        Led count:
        <input
            className="inline"
            type="number"
            min={0}
            max={999}
            defaultValue={newScriptInstance.ledCount}
            onChange={(e) => {
                if (e.target.value.length) {
                    let scriptInstance = newScriptInstance;
                    scriptInstance.ledCount = e.target.valueAsNumber;
                    setNewScriptInstance(scriptInstance);
                }
            }}
        />
        Autostart:
        <input
            className="inline"
            type="checkbox"
            defaultChecked={newScriptInstance.autoStart}
            onChange={(e) => {
                let scriptInstance = newScriptInstance;
                scriptInstance.autoStart = e.target.checked;
                setNewScriptInstance(scriptInstance);
            }}
        />
        <input
            className="inline"
            type="button"
            value="Add script instance"
            onClick={() => addScriptInstance(newScriptInstance)}
        />
    </div>;
};
