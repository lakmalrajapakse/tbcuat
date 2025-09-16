import LightningModal from "lightning/modal";
import { api } from "lwc";

import TIMESHEET_OBJECT from "@salesforce/schema/sirenum__Timesheet__c";
import CONTACT_FIELD from "@salesforce/schema/sirenum__Timesheet__c.sirenum__Worker__c";
import PO_NUMBER_FIELD from "@salesforce/schema/sirenum__Timesheet__c.sirenum__PO_Number__c";

export default class ShiftManagementTimesheetSummaryEditModal extends LightningModal {
    @api
    recordId;

    object = TIMESHEET_OBJECT;
    poNumberField = PO_NUMBER_FIELD;
    contactField = CONTACT_FIELD;

    _formReady = false;
    _submitting = false;

    get isLoading() {
        return this._submitting || !this._formReady;
    }

    get buttonsDisabled() {
        return !this._formReady || this._submitting;
    }

    handleUpdateClick() {
        const form = this.template.querySelector("lightning-record-edit-form");
        this._submitting = true;
        form.submit();
    }

    handleOnLoad() {
        this._formReady = true;
    }

    handleCancelClick() {
        this.close();
    }

    handleOnSuccess() {
        this._submitting = false;
        this.close({ success: true });
    }

    handleOnError() {
        this._submitting = false;
    }
}