import { useContext } from "react";
import { NewSegmentContext } from "../contexts/NewSegmentContext";
import { SegmentsContext } from "../contexts/SegmentsContext";
import { SelectedSegmentContext } from "../contexts/SelectedSegmentContext";
import { SelectedStateContext } from "../contexts/SelectedStateContext";
import { Segment } from "../types/Segment";

export const Segments = () => {
    const { selectedState } = useContext(SelectedStateContext)!;
    const segments = useContext(SegmentsContext)!;
    const { selectedSegment, setSelectedSegment } = useContext(SelectedSegmentContext)!;
    const { newSegment, setNewSegment } = useContext(NewSegmentContext)!;

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

    const options = segments.map((seg) => {
        const text = `${seg.begin} - ${seg.end}`;
        return <option key={seg.begin} value={seg.begin}>{text}</option>
    });

    return <div>
        <table><tbody><tr>
            <td>
                <select
                    size={Math.max(2, segments.length + 1)}
                    onChange={(e) => setSelectedSegment(segments[e.target.selectedIndex])}
                    defaultValue={selectedSegment.begin}
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
            defaultValue={newSegment.begin}
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
            defaultValue={newSegment.end}
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
            defaultValue={newSegment.scriptName}
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
