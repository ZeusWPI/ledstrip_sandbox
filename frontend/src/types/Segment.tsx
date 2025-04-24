export interface Segment {
    begin: number;
    end: number;
    scriptInstanceName: string;
}

export const segmentInit: Segment = {
    begin: 0,
    end: 0,
    scriptInstanceName: "",
};

export const compareSegments = (a: Segment, b: Segment) => a.begin - b.begin;
