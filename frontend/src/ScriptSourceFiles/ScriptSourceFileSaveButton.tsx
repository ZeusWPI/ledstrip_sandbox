import { useContext } from "react";
import { SelectedScriptSourceFileContext } from "../contexts/SelectedScriptSourceFileContext";
import { ScriptSourceCodeContext } from "../contexts/ScriptSourceCodeContext";
import { ScriptSourceCodeModifiedContext } from "../contexts/ScriptSourceCodeModifiedContext";

export const ScriptSourceFileSaveButton = () => {
    const { selectedScriptSourceFile } = useContext(SelectedScriptSourceFileContext)!;
    const { scriptSourceCode } = useContext(ScriptSourceCodeContext)!;
    const { scriptSourceCodeModified, setScriptSourceCodeModified } = useContext(ScriptSourceCodeModifiedContext)!;

    const saveScriptSourceFile = () => {
        fetch(`/api/script_source_files/${selectedScriptSourceFile}/`, {
            method: "PUT",
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ "sourceCode": scriptSourceCode }),
        }).then(() => {
            setScriptSourceCodeModified(false);
        });
    };

    return (
        <input
            className="inline"
            type="button"
            value="Save"
            onClick={() => saveScriptSourceFile()}
            disabled={!scriptSourceCodeModified}
        />
    );
};
