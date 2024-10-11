import { useEffect, useState } from "react";

export const MaxBrightness = () => {
    const [maxBrightness, setMaxBrightness] = useState<number>(0);

    const fetchMaxBrightness = () => {
        fetch("/api/config/max_brightness")
            .then(res => res.text())
            .then(text => setMaxBrightness(Number.parseInt(text)));
    };

    const applyMaxBrightness = () => {
        fetch("/api/config/max_brightness", {
            method: "PUT",
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ "maxBrightness": maxBrightness }),
        });
    };

    useEffect(fetchMaxBrightness, []);

    return <>
        <p>
            {"Max brightness: "}
            <input
                className="inline"
                type="number"
                min={1}
                max={255}
                value={maxBrightness}
                onChange={(e) => setMaxBrightness(e.target.valueAsNumber)}
            />
            <input
                className="inline"
                type="button"
                value="Apply"
                onClick={applyMaxBrightness}
            />
            <input
                className="inline"
                type="button"
                value="Refresh"
                onClick={fetchMaxBrightness}
            />
        </p>
    </>;
};
