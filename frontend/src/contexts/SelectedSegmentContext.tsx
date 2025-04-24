import { createContext, PropsWithChildren, useContext, useEffect, useState } from "react";
import { Segment, segmentInit } from "../types/Segment";
import { SegmentsContext } from "./SegmentsContext";
import { SelectedStateContext } from "./SelectedStateContext";

export interface SelectedSegmentContextValue {
    selectedSegment: Segment;
    setSelectedSegment: React.Dispatch<React.SetStateAction<Segment>>;
}

export const SelectedSegmentContext = createContext<SelectedSegmentContextValue | null>(null);

export const SelectedSegmentContextProvider = ({ children }: PropsWithChildren) => {
    const { selectedState } = useContext(SelectedStateContext)!;
    const segments = useContext(SegmentsContext)!;
    const [selectedSegment, setSelectedSegment] = useState<Segment>(segmentInit);

    useEffect(() => {
        setSelectedSegment({ begin: 0, end: 0, scriptInstanceName: "" })
    }, [selectedState]);

    useEffect(() => {
        if (selectedSegment.scriptInstanceName === "" && segments.length) {
            setSelectedSegment(segments[0]);
        }
    }, [selectedSegment, segments]);

    return (
        <SelectedSegmentContext.Provider
            value={{
                selectedSegment: selectedSegment,
                setSelectedSegment: setSelectedSegment,
            }}
        >
            {children}
        </SelectedSegmentContext.Provider>
    );
};
