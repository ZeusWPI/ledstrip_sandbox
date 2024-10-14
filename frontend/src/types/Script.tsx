export interface Script {
    name: string;
    fileName: string;
    ledCount: number;
    autoStart: boolean;
}

export const scriptInit: Script = {
    name: "",
    fileName: "",
    ledCount: 0,
    autoStart: false,
};

export const getExtension = (fileName: string) => {
    const split = fileName.split(".");
    return split[split.length - 1];
};
