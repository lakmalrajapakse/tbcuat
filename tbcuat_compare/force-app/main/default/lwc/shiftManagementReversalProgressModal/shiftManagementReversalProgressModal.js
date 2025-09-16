import { LightningElement, api } from 'lwc';
import LightningModal from "lightning/modal";

export default class ShiftManagementReversalProgressModal extends LightningModal {
    @api
    jobId;

    handleCancelClick() {
        this.close();
    }
}