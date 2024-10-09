import { useEffect, useState } from "react";

export const Fps = () => {
    const [fps, setFps] = useState<number>(0);

    const fetchFps = () => {
        fetch("/api/config/fps")
            .then(res => res.text())
            .then(text => setFps(Number.parseInt(text)));
    };

    const applyFps = () => {
        fetch("/api/config/fps", {
            method: "PUT",
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ "fps": fps }),
        });
    };

    useEffect(fetchFps, [setFps]);

    const fpsInputField = <input
        type="number"
        min={1}
        value={fps}
        onChange={(e) => setFps(e.target.valueAsNumber)}
    />;

    const fpsSetButton = <input
        type="button"
        value="Apply"
        onClick={applyFps}
    />;

    const fpsRefreshButton = <input
        type="button"
        value="Refresh"
        onClick={fetchFps}
    />;

    return <div>
        <p>fps: {fpsInputField} {fpsSetButton} {fpsRefreshButton}</p>
    </div>;
};