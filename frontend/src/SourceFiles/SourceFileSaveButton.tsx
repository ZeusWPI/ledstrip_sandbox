import { useContext } from "react";
import { SelectedSourceFileContext } from "../contexts/SelectedSourceFileContext";
import { SourceCodeContext } from "../contexts/SourceCodeContext";

export const SourceFileSaveButton = () => {
    const { selectedSourceFile, setSelectedSourceFile } = useContext(SelectedSourceFileContext)!;
    const { sourceCode, setSourceCode } = useContext(SourceCodeContext)!;

    const saveSourceFile = () => {
        fetch(`/api/source_files/${selectedSourceFile}/`, {
            method: "PUT",
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ "sourceCode": sourceCode }),
        }).then(() => {
            setSelectedSourceFile("");
            setSourceCode(null);
        });
    };

    return (
        <input
            className="inline"
            type="button"
            value="Save"
            onClick={() => saveSourceFile()}
            disabled={sourceCode === null}
        />
    );
};
