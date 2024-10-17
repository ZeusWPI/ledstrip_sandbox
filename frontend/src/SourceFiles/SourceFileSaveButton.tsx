import { useContext } from "react";
import { SelectedSourceFileContext } from "../contexts/SelectedSourceFileContext";
import { SourceCodeContext } from "../contexts/SourceCodeContext";
import { SourceCodeModifiedContext } from "../contexts/SourceCodeModifiedContext";

export const SourceFileSaveButton = () => {
    const { selectedSourceFile } = useContext(SelectedSourceFileContext)!;
    const { sourceCode } = useContext(SourceCodeContext)!;
    const { sourceCodeModified, setSourceCodeModified } = useContext(SourceCodeModifiedContext)!;

    const saveSourceFile = () => {
        fetch(`/api/source_files/${selectedSourceFile}/`, {
            method: "PUT",
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ "sourceCode": sourceCode }),
        }).then(() => {
            setSourceCodeModified(false);
        });
    };

    return (
        <input
            className="inline"
            type="button"
            value="Save"
            onClick={() => saveSourceFile()}
            disabled={!sourceCodeModified}
        />
    );
};
