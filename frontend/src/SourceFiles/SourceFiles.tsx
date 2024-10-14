import { useContext } from "react";
import { SelectedSourceFileContext } from "../contexts/SelectedSourceFileContext";
import { SourceFilesContext } from "../contexts/SourceFilesContext";
import { SourceFileEditor } from "./SourceFileEditor";
import { SourceCodeContext } from "../contexts/SourceCodeContext";
import { NewSourceFileContext } from "../contexts/NewSourceFileContext";

export const SourceFiles = () => {
    const sourceFiles = useContext(SourceFilesContext)!;
    const { selectedSourceFile, setSelectedSourceFile } = useContext(SelectedSourceFileContext)!;
    const { sourceCode, setSourceCode } = useContext(SourceCodeContext)!;
    const { newSourceFile, setNewSourceFile } = useContext(NewSourceFileContext)!;

    const saveSourceFile = () => {
        fetch(`/api/source_files/${selectedSourceFile}/`, {
            method: "PUT",
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ "sourceCode": sourceCode }),
        })
            .then(() => {
                setSelectedSourceFile("");
                setSourceCode(null);
            });
    };

    const createSourceFile = (name: string) => {
        fetch(`/api/source_files/`, {
            method: "POST",
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ sourceFile: {name: name, sourceCode: ""} }),
        });
    };

    return <div>
        <table><tbody><tr>
            <td>
                <table><tbody>
                    <tr><td>
                        <select
                            size={Math.max(2, sourceFiles.length + 1)}
                            onChange={(e) => setSelectedSourceFile(sourceFiles[e.target.selectedIndex])}
                            disabled={sourceCode !== null}
                        >
                            {sourceFiles.sort().map(name => {
                                return (
                                    <option
                                        key={name}
                                        value={name}
                                        selected={selectedSourceFile === name}
                                    >
                                        {name}
                                    </option>
                                );
                            })}
                        </select>
                    </td></tr>
                    <tr><td>
                        <input
                            className="inline"
                            type="button"
                            value="Save"
                            onClick={() => saveSourceFile()}
                            disabled={sourceCode === null}
                        />
                    </td></tr>
                </tbody></table>
            </td>
            <td>
                <SourceFileEditor />
            </td>
        </tr></tbody></table>
        {!selectedSourceFile.length && <>
            <br />
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
        </>}
    </div>;
};
