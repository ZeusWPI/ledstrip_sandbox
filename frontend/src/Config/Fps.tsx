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

    useEffect(fetchFps, []);

    return <>
        <p>
            {"Fps: "}
            <input
                className="inline"
                type="number"
                min={1}
                max={99}
                value={fps}
                onChange={(e) => setFps(e.target.valueAsNumber)}
            />
            <input
                className="inline"
                type="button"
                value="Apply"
                onClick={applyFps}
            />
            <input
                className="inline"
                type="button"
                value="Refresh"
                onClick={fetchFps}
            />
        </p>
    </>;
};
