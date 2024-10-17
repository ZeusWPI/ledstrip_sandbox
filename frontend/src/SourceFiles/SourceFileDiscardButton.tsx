import { useContext } from "react";
import { SourceCodeContext } from "../contexts/SourceCodeContext";
import { SourceCodeModifiedContext } from "../contexts/SourceCodeModifiedContext";
import { SelectedSourceFileContext } from "../contexts/SelectedSourceFileContext";

export const SourceFileDiscardButton = () => {
    const { setSelectedSourceFile } = useContext(SelectedSourceFileContext)!;
    const { setSourceCode } = useContext(SourceCodeContext)!;
    const { sourceCodeModified, setSourceCodeModified } = useContext(SourceCodeModifiedContext)!;

    return (
        <input
            className="inline"
            type="button"
            value="Discard"
            onClick={() => {
                setSelectedSourceFile("");
                setSourceCode(null);
                setSourceCodeModified(false);
            }}
            disabled={!sourceCodeModified}
        />
    );
};
