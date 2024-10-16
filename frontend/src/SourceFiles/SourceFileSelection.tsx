import { useContext, useEffect, useRef } from "react";
import { SelectedSourceFileContext } from "../contexts/SelectedSourceFileContext";
import { SourceFilesContext } from "../contexts/SourceFilesContext";
import { SourceCodeContext } from "../contexts/SourceCodeContext";

export const SourceFileSelection = () => {
    const sourceFiles = useContext(SourceFilesContext)!;
    const { setSelectedSourceFile } = useContext(SelectedSourceFileContext)!;
    const { sourceCode } = useContext(SourceCodeContext)!;
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
            disabled={sourceCode !== null}
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
