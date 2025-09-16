import { LightningElement, api } from "lwc";

export default class JobOffersDataTableActions extends LightningElement {
    @api recordId;

    handleAcceptClick() {
        const acceptClickEvent = new CustomEvent("acceptclick", {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                recordId: this.recordId
            }
        });
        this.dispatchEvent(acceptClickEvent);
    }

    handleDeclineClick() {
        const declineClickEvent = new CustomEvent("declineclick", {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                recordId: this.recordId
            }
        });
        this.dispatchEvent(declineClickEvent);
    }
}