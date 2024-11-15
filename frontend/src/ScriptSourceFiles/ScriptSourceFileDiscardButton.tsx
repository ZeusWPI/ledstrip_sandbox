import { useContext } from "react";
import { ScriptSourceCodeContext } from "../contexts/ScriptSourceCodeContext";
import { ScriptSourceCodeModifiedContext } from "../contexts/ScriptSourceCodeModifiedContext";
import { SelectedScriptSourceFileContext } from "../contexts/SelectedScriptSourceFileContext";

export const ScriptSourceFileDiscardButton = () => {
    const { setSelectedScriptSourceFile } = useContext(SelectedScriptSourceFileContext)!;
    const { setScriptSourceCode } = useContext(ScriptSourceCodeContext)!;
    const { scriptSourceCodeModified, setScriptSourceCodeModified } = useContext(ScriptSourceCodeModifiedContext)!;

    return (
        <input
            className="inline"
            type="button"
            value="Discard"
            onClick={() => {
                setSelectedScriptSourceFile("");
                setScriptSourceCode(null);
                setScriptSourceCodeModified(false);
            }}
            disabled={!scriptSourceCodeModified}
        />
    );
};
