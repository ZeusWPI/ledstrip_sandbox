import { PropsWithChildren, StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import { ActiveStateContextProvider } from "./contexts/ActiveStateContext";
import { NewScriptContextProvider } from "./contexts/NewScriptContext";
import { NewSegmentContextProvider } from "./contexts/NewSegmentContext";
import { NewSourceFileContextProvider } from "./contexts/NewSourceFileContext";
import { NewStateContextProvider } from "./contexts/NewStateContext";
import { ScriptNamesContextProvider } from "./contexts/ScriptNamesContext";
import { SegmentsContextProvider } from "./contexts/SegmentsContext";
import { SelectedScriptContextProvider } from "./contexts/SelectedScriptContext";
import { SelectedScriptNameContextProvider } from "./contexts/SelectedScriptNameContext";
import { SelectedScriptRunningContextProvider } from "./contexts/SelectedScriptRunningContext";
import { SelectedSegmentContextProvider } from "./contexts/SelectedSegmentContext";
import { SelectedSourceFileContextProvider } from "./contexts/SelectedSourceFileContext";
import { SelectedStateContextProvider } from "./contexts/SelectedStateContext";
import { SourceCodeContextProvider } from "./contexts/SourceCodeContext";
import { SourceFilesContextProvider } from "./contexts/SourceFilesContext";
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

        ScriptNamesContextProvider,
        SelectedScriptNameContextProvider,
        SelectedScriptContextProvider,
        SelectedScriptRunningContextProvider,
        NewScriptContextProvider,

        SourceFilesContextProvider,
        SelectedSourceFileContextProvider,
        SourceCodeContextProvider,
        NewSourceFileContextProvider,
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
