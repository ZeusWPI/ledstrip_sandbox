import { BrowserRouter, Navigate, Route, Routes, useNavigate } from "react-router-dom";
import { ConfigPage } from "./Config/ConfigPage";
import { ScriptInstancesPage } from "./Scripts/ScriptInstancesPage";
import { ScriptSourceFilesPage } from "./ScriptSourceFiles/ScriptSourceFilesPage";
import { StatesSegmentsPage } from "./StatesSegments/StatesSegmentsPage";

import "./App.css";

interface TabProps {
    name: string;
    path: string;
};

const Tab = ({ name, path }: TabProps) => {
    const navigate = useNavigate();
    let classes = "tab";
    if (window.location.pathname === path) {
        classes += " tab-selected";
    }
    return <>
        <div
            className={classes}
            onClick={() => navigate(path)}
            key={name}
        >
            {name}
        </div>
    </>;
};

export const App = () => {
    return <>
        <BrowserRouter>
            <h2>Ledstrip</h2>
            <div className="tabList">
                <Tab path="/statesSegments" name="States and segments" />
                <Tab path="/scriptInstances" name="Script instances" />
                <Tab path="/scriptSourceFiles" name="Script source files" />
                <Tab path="/config" name="Config" />
            </div>
            <Routes>
                <Route path="/" element={<Navigate to="statesSegments" />} />
                <Route path="/statesSegments" element={<StatesSegmentsPage />} />
                <Route path="/scriptInstances" element={<ScriptInstancesPage />} />
                <Route path="/scriptSourceFiles" element={<ScriptSourceFilesPage />} />
                <Route path="/config" element={<ConfigPage />} />
                <Route path="/*" element={<Navigate to="/" />} />
            </Routes>
        </BrowserRouter>
    </>;
};
