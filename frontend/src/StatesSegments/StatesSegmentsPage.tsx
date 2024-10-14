import { useContext } from "react";
import { SelectedStateContext } from "../contexts/SelectedStateContext";
import { Segments } from "./Segments";
import { States } from "./States";

export const StatesSegmentsPage = () => {
    const { selectedState } = useContext(SelectedStateContext)!;

    return <>
        <h3>States</h3>
        <States
        />
        <h3>Segments in state "{selectedState}"</h3>
        <Segments />
    </>
};
