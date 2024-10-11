import { Fps } from "./Fps";
import { MaxBrightness } from "./MaxBrightness";

import "./ConfigPage.css";

export const ConfigPage = () => {
    return <>
        <h3>Config</h3>
        <Fps />
        <MaxBrightness />
    </>;
}
