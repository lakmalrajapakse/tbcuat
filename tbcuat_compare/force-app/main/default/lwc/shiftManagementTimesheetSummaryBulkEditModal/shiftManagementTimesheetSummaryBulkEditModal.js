import LightningModal from "lightning/modal";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { api, wire } from "lwc";

import updateTimesheets from "@salesforce/apex/SMTimesheetSummaryBulkEditController.updateTimesheets";
import TIMESHEET_OBJECT from "@salesforce/schema/sirenum__Timesheet__c";

import { handleTransactionError } from "c/utils";

export default class ShiftManagementTimesheetSummaryBulkEditModal extends LightningModal {
    _submitting = false;
    _poNumber = "";

    poNumberFieldLabel = "";
    formReady = false;

    @api
    recordIds;

    @wire(getObjectInfo, { objectApiName: TIMESHEET_OBJECT })
    timesheetObjectInfo({ data }) {
        if (data) {
            this.poNumberFieldLabel = data.fields.sirenum__PO_Number__c.label;
            this.formReady = true;
        }
    }

    get isLoading() {
        return this._submitting || !this.formReady;
    }

    get buttonsDisabled() {
        return !this.formReady || this._submitting;
    }

    handlePoNumberChange(event) {
        this._poNumber = event.target.value;
    }

    async handleUpdateClick() {
        let success = false;
        try {
            this._submitting = true;

            const payload = JSON.stringify({
                recordIds: this.recordIds,
                poNumber: this._poNumber
            });

            await updateTimesheets({
                timesheetsBulkEditJson: payload
            });

            success = true;
        } catch (ex) {
            handleTransactionError("Update Error", ex);
        }

        this._submitting = false;

        this.close({ success });
    }

    handleCancelClick() {
        this.close();
    }
}