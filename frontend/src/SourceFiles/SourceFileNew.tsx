import { useContext } from "react";
import { NewSourceFileContext } from "../contexts/NewSourceFileContext";

export const SourceFileNew = () => {
    const { newSourceFile, setNewSourceFile } = useContext(NewSourceFileContext)!;

    const createSourceFile = (name: string) => {
        fetch(`/api/source_files/`, {
            method: "POST",
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ sourceFile: { name: name, sourceCode: "" } }),
        });
    };

    return <>
        Name:
        <input
            className="inline"
            type="text"
            defaultValue={newSourceFile}
            onChange={(e) => setNewSourceFile(e.target.value)}
        />
        <input
            className="inline"
            type="button"
            value="Create source file"
            onClick={() => createSourceFile(newSourceFile)}
        />
    </>;
};
