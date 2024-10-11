import { useEffect, useState } from "react";

export interface SegmentsProps {
    selectedState: string;
};

interface Segment {
    begin: number;
    end: number;
    scriptName: string;
}

const segmentInit: Segment = {
    begin: 0,
    end: 0,
    scriptName: "",
};

const compareSegments = (a: Segment, b: Segment) => a.begin - b.begin;

export const Segments = ({ selectedState }: SegmentsProps) => {
    const [segments, setSegments] = useState<Segment[]>([]);
    const [selectedSegment, setSelectedSegment] = useState<Segment>(segmentInit);
    const [newSegment, setNewSegment] = useState<Segment>(segmentInit);

    const fetchSegments = () => {
        if (selectedState.length) {
            fetch(`/api/states/${selectedState}/segments/`)
                .then((res) => res.json())
                .then((segs: Segment[]) => setSegments(segs.sort(compareSegments)));
        }
    };

    const addSegment = (segment: Segment) => {
        fetch(`/api/states/${selectedState}/segments/`, {
            method: "POST",
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ "segment": segment }),
        });
    };

    const removeSegment = (begin: number) => {
        fetch(`/api/states/${selectedState}/segments/${begin}/`, {
            method: "DELETE",
        });
    };

    useEffect(() => {
        fetchSegments();
        const interval = setInterval(fetchSegments, 500);
        return () => clearInterval(interval);
    }, [selectedState]);

    useEffect(() => {
        setSelectedSegment({ begin: 0, end: 0, scriptName: "" })
    }, [selectedState]);

    useEffect(() => {
        if (selectedSegment.scriptName === "" && segments.length) {
            setSelectedSegment(segments[0]);
        }
    }, [selectedSegment, segments]);

    const options = segments.map((seg) => {
        const text = `${seg.begin} - ${seg.end}`;
        return <option key={seg.begin}>{text}</option>
    });

    return <div>
        <table><tbody><tr>
            <td>
                <select
                    size={Math.max(2, segments.length + 1)}
                    onChange={(e) => setSelectedSegment(segments[e.target.selectedIndex])}
                >
                    {options}
                </select>
            </td>
            <td>
                Selected: <br />
                <table style={{ marginLeft: "8px" }}><tbody>
                    <tr><td>Begin:</td><td>{selectedSegment.begin}</td></tr>
                    <tr><td>End:</td><td>{selectedSegment.end}</td></tr>
                    <tr><td>Led count:</td><td>{selectedSegment.end - selectedSegment.begin}</td></tr>
                    <tr><td>Script name:</td><td>"{selectedSegment.scriptName}"</td></tr>
                </tbody></table>
                <input
                    className="inline"
                    type="button"
                    value="Remove segment"
                    onClick={() => removeSegment(selectedSegment.begin)}
                />
            </td>
        </tr></tbody></table>
        Begin:
        <input
            className="inline"
            type="number"
            min={0}
            max={999}
            defaultValue={0}
            onChange={(e) => {
                if (e.target.value.length) {
                    let seg = newSegment;
                    seg.begin = e.target.valueAsNumber;
                    setNewSegment(seg);
                }
            }}
        />
        End:
        <input
            className="inline"
            type="number"
            min={0}
            max={999}
            defaultValue={0}
            onChange={(e) => {
                if (e.target.value.length) {
                    let seg = newSegment;
                    seg.end = e.target.valueAsNumber;
                    setNewSegment(seg);
                }
            }}
        />
        Script name:
        <input
            className="inline"
            type="text"
            onChange={(e) => {
                let seg = newSegment;
                seg.scriptName = e.target.value;
                setNewSegment(seg);
            }}
        />
        <input
            className="inline"
            type="button"
            value="Add segment"
            onClick={() => addSegment(newSegment)}
        />
    </div>;
};
