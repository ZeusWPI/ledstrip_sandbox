export interface ScriptInstance {
    name: string;
    sourceFileName: string;
    ledCount: number;
    autoStart: boolean;
}

export const scriptInstanceInit: ScriptInstance = {
    name: "",
    sourceFileName: "",
    ledCount: 0,
    autoStart: false,
};

export const getExtension = (sourceFileName: string) => {
    const split = sourceFileName.split(".");
    return split[split.length - 1];
};
