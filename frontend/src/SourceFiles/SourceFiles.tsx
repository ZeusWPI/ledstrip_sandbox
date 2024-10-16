import { useContext } from "react";
import { SelectedSourceFileContext } from "../contexts/SelectedSourceFileContext";
import { SourceFileEditor } from "./SourceFileEditor";
import { SourceFileNew } from "./SourceFileNew";
import { SourceFileSaveButton } from "./SourceFileSaveButton";
import { SourceFileSelection } from "./SourceFileSelection";

export const SourceFiles = () => {
    const { selectedSourceFile } = useContext(SelectedSourceFileContext)!;

    return <div>
        <table><tbody><tr>
            <td>
                <table><tbody>
                    <tr><td>
                        <SourceFileSelection />
                    </td></tr>
                    <tr><td>
                        <SourceFileSaveButton />
                    </td></tr>
                </tbody></table>
            </td>
            <td>
                {selectedSourceFile && <SourceFileEditor />}
            </td>
        </tr></tbody></table>
        <br />
        {!selectedSourceFile.length && <SourceFileNew />}
    </div>;
};
