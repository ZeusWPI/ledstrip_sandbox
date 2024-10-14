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
