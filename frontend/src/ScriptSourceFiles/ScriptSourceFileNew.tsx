import { useContext } from "react";
import { NewScriptSourceFileContext } from "../contexts/NewScriptSourceFileContext";
import { ScriptSourceCodeModifiedContext } from "../contexts/ScriptSourceCodeModifiedContext";

export const ScriptSourceFileNew = () => {
    const { newScriptSourceFile, setNewScriptSourceFile } = useContext(NewScriptSourceFileContext)!;
    const { scriptSourceCodeModified } = useContext(ScriptSourceCodeModifiedContext)!;

    const createScriptSourceFile = (name: string) => {
        fetch(`/api/script_source_files/`, {
            method: "POST",
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ scriptSourceFile: { name: name, sourceCode: "" } }),
        });
    };

    if (!scriptSourceCodeModified) {
        return <>
            Name:
            <input
                className="inline"
                type="text"
                defaultValue={newScriptSourceFile}
                onChange={(e) => setNewScriptSourceFile(e.target.value)}
            />
            <input
                className="inline"
                type="button"
                value="Create script source file"
                onClick={() => createScriptSourceFile(newScriptSourceFile)}
            />
        </>;
    } else {
        return <></>;
    }
};
