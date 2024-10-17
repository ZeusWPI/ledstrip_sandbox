import { useContext, useEffect, useRef } from "react";
import { SelectedSourceFileContext } from "../contexts/SelectedSourceFileContext";
import { SourceCodeContext } from "../contexts/SourceCodeContext";
import { SourceCodeModifiedContext } from "../contexts/SourceCodeModifiedContext";
import { SourceFilesContext } from "../contexts/SourceFilesContext";

export const SourceFileSelection = () => {
    const sourceFiles = useContext(SourceFilesContext)!;
    const { setSelectedSourceFile } = useContext(SelectedSourceFileContext)!;
    const { sourceCode } = useContext(SourceCodeContext)!;
    const { sourceCodeModified } = useContext(SourceCodeModifiedContext)!;
    const selectElementRef = useRef<HTMLSelectElement | null>(null);

    // Deselect on save
    useEffect(() => {
        if (sourceCode === null) {
            [...selectElementRef.current!.children].forEach(child => {
                (child as HTMLOptionElement).selected = false;
            });
        }
    }, [sourceCode]);

    return (
        <select
            size={Math.max(2, sourceFiles.length + 1)}
            onChange={(e) => setSelectedSourceFile(sourceFiles[e.target.selectedIndex])}
            disabled={sourceCodeModified}
            ref={selectElementRef}
        >
            {sourceFiles.sort().map(name => {
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
