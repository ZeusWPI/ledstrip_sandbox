import { BrowserRouter, Navigate, Route, Routes, useNavigate } from "react-router-dom";
import { ConfigPage } from "./Config/ConfigPage";
import { ScriptsPage } from "./Scripts/ScriptsPage";
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
                <Tab path="/scripts" name="Scripts" />
                <Tab path="/config" name="Config" />
            </div>
            <Routes>
                <Route path="/" element={<Navigate to="statesSegments" />} />
                <Route path="/statesSegments" element={<StatesSegmentsPage />} />
                <Route path="/scripts" element={<ScriptsPage />} />
                <Route path="/config" element={<ConfigPage />} />
                <Route path="/*" element={<Navigate to="/" />} />
            </Routes>
        </BrowserRouter>
    </>;
};
