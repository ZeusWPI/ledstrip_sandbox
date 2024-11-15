import { useContext, useEffect, useRef } from "react";
import { SelectedScriptSourceFileContext } from "../contexts/SelectedScriptSourceFileContext";
import { ScriptSourceCodeContext } from "../contexts/ScriptSourceCodeContext";
import { ScriptSourceCodeModifiedContext } from "../contexts/ScriptSourceCodeModifiedContext";
import { ScriptSourceFilesContext } from "../contexts/ScriptSourceFilesContext";

export const ScriptSourceFileSelection = () => {
    const scriptSourceFiles = useContext(ScriptSourceFilesContext)!;
    const { setSelectedScriptSourceFile } = useContext(SelectedScriptSourceFileContext)!;
    const { scriptSourceCode } = useContext(ScriptSourceCodeContext)!;
    const { scriptSourceCodeModified } = useContext(ScriptSourceCodeModifiedContext)!;
    const selectElementRef = useRef<HTMLSelectElement | null>(null);

    // Deselect on save
    useEffect(() => {
        if (scriptSourceCode === null) {
            [...selectElementRef.current!.children].forEach(child => {
                (child as HTMLOptionElement).selected = false;
            });
        }
    }, [scriptSourceCode]);

    return (
        <select
            size={Math.max(2, scriptSourceFiles.length + 1)}
            onChange={(e) => setSelectedScriptSourceFile(scriptSourceFiles[e.target.selectedIndex])}
            disabled={scriptSourceCodeModified}
            ref={selectElementRef}
        >
            {scriptSourceFiles.sort().map(name => {
                return (
                    <option
                        key={name}
                        value={name}
                    >
                        {name}
                    </option>
                );
            })}
        </select>
    );
};
