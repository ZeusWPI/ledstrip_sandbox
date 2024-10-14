import { useContext } from "react";
import { NewScriptContext } from "../contexts/NewScriptContext";
import { ScriptNamesContext } from "../contexts/ScriptNamesContext";
import { SelectedScriptContext } from "../contexts/SelectedScriptContext";
import { SelectedScriptNameContext } from "../contexts/SelectedScriptNameContext";
import { SelectedScriptRunningContext } from "../contexts/SelectedScriptRunningContext";
import { Script } from "../types/Script";

import "./Scripts.css";

export const Scripts = () => {
    const scriptNames = useContext(ScriptNamesContext)!;
    const { selectedScriptName, setSelectedScriptName } = useContext(SelectedScriptNameContext)!;
    const selectedScript = useContext(SelectedScriptContext)!;
    const selectedScriptRunning = useContext(SelectedScriptRunningContext)!;
    const { newScript, setNewScript } = useContext(NewScriptContext)!;

    const addScript = (script: Script) => {
        fetch(`/api/scripts/`, {
            method: "POST",
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ "script": script }),
        });
    };

    const removeScript = (name: string) => {
        fetch(`/api/scripts/${name}/`, {
            method: "DELETE",
        });
    };

    const startScript = (name: string) => {
        fetch(`/api/scripts/${name}/start`, {
            method: "POST",
        });
    };

    const stopScript = (name: string) => {
        fetch(`/api/scripts/${name}/stop`, {
            method: "POST",
        });
    };

    const reloadScript = (name: string) => {
        fetch(`/api/scripts/${name}/reload`, {
            method: "POST",
        });
    };

    return <div>
        <table><tbody><tr>
            <td>
                <select
                    size={Math.max(2, scriptNames.length + 1)}
                    onChange={(e) => setSelectedScriptName(scriptNames[e.target.selectedIndex])}
                    defaultValue={selectedScriptName}
                >
                    {scriptNames.sort().map(name => <option key={name} value={name}>{name}</option>)}
                </select>
            </td>
            <td>
                Selected: "{selectedScriptName}"
                <table style={{ marginLeft: "8px" }}><tbody>
                    <tr><td>File name:</td><td>{selectedScript.fileName}</td></tr>
                    <tr><td>Led count:</td><td>{selectedScript.ledCount}</td></tr>
                    <tr><td>Auto start:</td><td>{selectedScript.autoStart && "true" || "false"}</td></tr>
                    <tr><td>Running:</td><td>{selectedScriptRunning && "true" || "false"}</td></tr>
                </tbody></table>
                <input
                    className="inline"
                    type="button"
                    value="Start script"
                    disabled={selectedScriptRunning}
                    onClick={() => startScript(selectedScriptName)}
                />
                <input
                    className="inline"
                    type="button"
                    value="Stop script"
                    disabled={!selectedScriptRunning}
                    onClick={() => stopScript(selectedScriptName)}
                />
                <input
                    className="inline"
                    type="button"
                    value="Reload script"
                    disabled={selectedScriptRunning}
                    onClick={() => reloadScript(selectedScriptName)}
                />
                <input
                    className="inline"
                    type="button"
                    value="Remove script"
                    disabled={selectedScriptRunning}
                    onClick={() => removeScript(selectedScriptName)}
                />
            </td>
        </tr></tbody></table>
        Name:
        <input
            className="inline"
            type="text"
            defaultValue={newScript.name}
            onChange={(e) => {
                if (e.target.value.length) {
                    let script = newScript;
                    script.name = e.target.value;
                    setNewScript(script);
                }
            }}
        />
        File name:
        <input
            className="inline"
            type="text"
            defaultValue={newScript.fileName}
            onChange={(e) => {
                if (e.target.value.length) {
                    let script = newScript;
                    script.fileName = e.target.value;
                    setNewScript(script);
                }
            }}
        />
        Led count:
        <input
            className="inline"
            type="number"
            min={0}
            max={999}
            defaultValue={newScript.ledCount}
            onChange={(e) => {
                if (e.target.value.length) {
                    let script = newScript;
                    script.ledCount = e.target.valueAsNumber;
                    setNewScript(script);
                }
            }}
        />
        Autostart:
        <input
            className="inline"
            type="checkbox"
            defaultChecked={newScript.autoStart}
            onChange={(e) => {
                let script = newScript;
                script.autoStart = e.target.checked;
                setNewScript(script);
            }}
        />
        <input
            className="inline"
            type="button"
            value="Add script"
            onClick={() => addScript(newScript)}
        />
    </div>;
};
