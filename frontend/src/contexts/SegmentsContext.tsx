import { createContext, PropsWithChildren, useContext, useEffect, useState } from "react";
import { compareSegments, Segment } from "../types/Segment";
import { SelectedStateContext } from "./SelectedStateContext";

export const SegmentsContext = createContext<Segment[] | null>(null);

export const SegmentsContextProvider = ({ children }: PropsWithChildren) => {
    const { selectedState } = useContext(SelectedStateContext)!;
    const [segments, setSegments] = useState<Segment[]>([]);

    useEffect(() => {
        if (selectedState.length) {
            const fn = () => {
                fetch(`/api/states/${selectedState}/segments/`)
                    .then((res) => res.json())
                    .then((segs: Segment[]) => setSegments(segs.sort(compareSegments)));
            };
            fn();
            const interval = setInterval(fn, 500);
            return () => clearInterval(interval);
        }
    }, [selectedState]);

    return (
        <SegmentsContext.Provider
            value={segments}
        >
            {children}
        </SegmentsContext.Provider>
    );
};
