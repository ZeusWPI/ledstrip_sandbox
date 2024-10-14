import { createContext, PropsWithChildren, useState } from "react";
import { Segment, segmentInit } from "../types/Segment";

export interface NewSegmentContextValue {
    newSegment: Segment;
    setNewSegment: React.Dispatch<React.SetStateAction<Segment>>;
}

export const NewSegmentContext = createContext<NewSegmentContextValue | null>(null);

export const NewSegmentContextProvider = ({ children }: PropsWithChildren) => {
    const [newSegment, setNewSegment] = useState<Segment>(segmentInit);

    return (
        <NewSegmentContext.Provider
            value={{
                newSegment: newSegment,
                setNewSegment: setNewSegment,
            }}
        >
            {children}
        </NewSegmentContext.Provider>
    );
};
