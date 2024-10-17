import { useContext } from "react";
import { SelectedSourceFileContext } from "../contexts/SelectedSourceFileContext";
import { SourceFileDiscardButton } from "./SourceFileDiscardButton";
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
                        <SourceFileDiscardButton />
                    </td></tr>
                </tbody></table>
            </td>
            <td>
                {selectedSourceFile && <SourceFileEditor />}
            </td>
        </tr></tbody></table>
        <br />
        {!selectedSourceFile && <SourceFileNew />}
    </div>;
};
