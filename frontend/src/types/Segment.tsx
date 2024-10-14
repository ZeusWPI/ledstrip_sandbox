export interface Segment {
    begin: number;
    end: number;
    scriptName: string;
}

export const segmentInit: Segment = {
    begin: 0,
    end: 0,
    scriptName: "",
};

export const compareSegments = (a: Segment, b: Segment) => a.begin - b.begin;
