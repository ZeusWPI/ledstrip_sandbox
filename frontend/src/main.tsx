import { PropsWithChildren, StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import { ActiveStateContextProvider } from "./contexts/ActiveStateContext";
import { NewScriptInstanceContextProvider } from "./contexts/NewScriptInstanceContext";
import { NewSegmentContextProvider } from "./contexts/NewSegmentContext";
import { NewScriptSourceFileContextProvider } from "./contexts/NewScriptSourceFileContext";
import { NewStateContextProvider } from "./contexts/NewStateContext";
import { ScriptInstanceNamesContextProvider } from "./contexts/ScriptInstanceNamesContext";
import { SegmentsContextProvider } from "./contexts/SegmentsContext";
import { SelectedScriptInstanceContextProvider } from "./contexts/SelectedScriptInstanceContext";
import { SelectedScriptInstanceNameContextProvider } from "./contexts/SelectedScriptInstanceNameContext";
import { SelectedScriptInstanceRunningContextProvider } from "./contexts/SelectedScriptInstanceRunningContext";
import { SelectedSegmentContextProvider } from "./contexts/SelectedSegmentContext";
import { SelectedScriptSourceFileContextProvider } from "./contexts/SelectedScriptSourceFileContext";
import { SelectedStateContextProvider } from "./contexts/SelectedStateContext";
import { ScriptSourceCodeModifiedContextProvider } from "./contexts/ScriptSourceCodeModifiedContext";
import { ScriptSourceCodeContextProvider } from "./contexts/ScriptSourceCodeContext";
import { ScriptSourceFilesContextProvider } from "./contexts/ScriptSourceFilesContext";
import { StatesContextProvider } from "./contexts/StatesContext";

import "./main.css";

const AppProviders = ({ children }: PropsWithChildren) => {
    const providers = [
        StatesContextProvider,
        ActiveStateContextProvider,
        SelectedStateContextProvider,
        NewStateContextProvider,

        SegmentsContextProvider,
        SelectedSegmentContextProvider,
        NewSegmentContextProvider,

        ScriptInstanceNamesContextProvider,
        SelectedScriptInstanceNameContextProvider,
        SelectedScriptInstanceContextProvider,
        SelectedScriptInstanceRunningContextProvider,
        NewScriptInstanceContextProvider,

        ScriptSourceFilesContextProvider,
        SelectedScriptSourceFileContextProvider,
        ScriptSourceCodeContextProvider,
        ScriptSourceCodeModifiedContextProvider,
        NewScriptSourceFileContextProvider,
    ];
    return providers.reduceRight((acc, Provider) => <Provider>{acc}</Provider>, children);
};

createRoot(document.getElementById("root")!).render(
    <StrictMode>
        <AppProviders>
            <App />
        </AppProviders>
    </StrictMode>
);
