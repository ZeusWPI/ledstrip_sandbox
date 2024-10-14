import { useContext } from "react";
import { SelectedSourceFileContext } from "../contexts/SelectedSourceFileContext";
import { SourceFilesContext } from "../contexts/SourceFilesContext";
import { SourceFileEditor } from "./SourceFileEditor";
import { SourceCodeContext } from "../contexts/SourceCodeContext";

import "./SourceFilesPage.css"

export const SourceFilesPage = () => {
    const sourceFiles = useContext(SourceFilesContext)!;
    const { selectedSourceFile, setSelectedSourceFile } = useContext(SelectedSourceFileContext)!;
    const { sourceCode, setSourceCode } = useContext(SourceCodeContext)!;

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
    </div>;
};
