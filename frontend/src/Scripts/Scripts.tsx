import { useEffect, useState } from "react";

import "./Scripts.css"

export interface ScriptsProps {
    selectedState: string;
};

interface Script {
    name: string;
    fileName: string;
    ledCount: number;
    autoStart: boolean;
}

const scriptInit: Script = {
    name: "",
    fileName: "",
    ledCount: 0,
    autoStart: false,
};

export const Scripts = () => {
    const [scriptNames, setScriptNames] = useState<string[]>([]);
    const [selectedScriptName, setSelectedScriptName] = useState<string>("");
    const [selectedScript, setSelectedScript] = useState<Script>(scriptInit);
    const [selectedScriptRunning, setSelectedScriptRunning] = useState<boolean>(false);
    const [newScript, setNewScript] = useState<Script>(scriptInit);

    const fetchScripts = () => {
        fetch("/api/scripts/")
            .then(res => res.json())
            .then(json => setScriptNames(json));
    };

    const fetchScript = (name: string) => {
        fetch(`/api/scripts/${name}/`)
            .then(res => res.json())
            .then(json => setSelectedScript(json));
        fetch(`/api/scripts/${name}/running`)
            .then(res => res.text())
            .then(text => setSelectedScriptRunning(JSON.parse(text)));
    };

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

    useEffect(() => {
        fetchScripts();
        const interval = setInterval(fetchScripts, 500);
        return () => clearInterval(interval);
    }, []);

    useEffect(() => {
        if (selectedScriptName !== "") {
            fetchScript(selectedScriptName);
            const interval = setInterval(() => fetchScript(selectedScriptName), 500);
            return () => clearInterval(interval);
        }
    }, [selectedScriptName]);

    useEffect(() => {
        if (selectedScriptName === "" && scriptNames.length) {
            setSelectedScriptName(scriptNames[0]);
        }
    }, [selectedScriptName, scriptNames]);

    return <div>
        <table><tbody><tr>
            <td>
                <select
                    size={Math.max(2, scriptNames.length + 1)}
                    onChange={(e) => setSelectedScriptName(scriptNames[e.target.selectedIndex])}
                >
                    {scriptNames.map(name => <option key={name}>{name}</option>)}
                </select>
            </td>
            <td>
                Selected: "{selectedScriptName}"
                <table style={{ marginLeft: "8px" }}><tbody>
                    <tr><td>Name:</td><td>{selectedScript.name}</td></tr>
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
            defaultValue={0}
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
            onChange={(e) => {
                if (e.target.value.length) {
                    let script = newScript;
                    console.log(e.target.value);
                    setNewScript(script);
                }
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
