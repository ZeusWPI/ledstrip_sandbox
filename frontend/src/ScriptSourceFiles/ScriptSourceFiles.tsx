import { useContext } from "react";
import { SelectedScriptSourceFileContext } from "../contexts/SelectedScriptSourceFileContext";
import { ScriptSourceFileDiscardButton } from "./ScriptSourceFileDiscardButton";
import { ScriptSourceFileEditor } from "./ScriptSourceFileEditor";
import { ScriptSourceFileNew } from "./ScriptSourceFileNew";
import { ScriptSourceFileSaveButton } from "./ScriptSourceFileSaveButton";
import { ScriptSourceFileSelection } from "./ScriptSourceFileSelection";

export const ScriptSourceFiles = () => {
    const { selectedScriptSourceFile } = useContext(SelectedScriptSourceFileContext)!;

    return <div>
        <table><tbody><tr>
            <td>
                <table><tbody>
                    <tr><td>
                        <ScriptSourceFileSelection />
                    </td></tr>
                    <tr><td>
                        <ScriptSourceFileSaveButton />
                        <ScriptSourceFileDiscardButton />
                    </td></tr>
                </tbody></table>
            </td>
            <td>
                {selectedScriptSourceFile && <ScriptSourceFileEditor />}
            </td>
        </tr></tbody></table>
        <br />
        {<ScriptSourceFileNew />}
    </div>;
};
