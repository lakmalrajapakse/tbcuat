import { LightningElement } from "lwc";

export default class ShiftManagementAdjustmentTypeSelector extends LightningElement {
    value = "";

    get options() {
        return [
            { label: "Pay", value: "pay" },
            { label: "Charge", value: "charge" },
            { label: "Pay / Charge", value: "payCharge" }
        ];
    }

    handleChange(event) {
        const selectedOption = event.detail.value;
        this.dispatchEvent(new CustomEvent("selectionchange", { detail: selectedOption }));
    }
}