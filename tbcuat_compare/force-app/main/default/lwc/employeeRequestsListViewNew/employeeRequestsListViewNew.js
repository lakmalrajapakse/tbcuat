import { api } from "lwc";

import LightningModal from "lightning/modal";
import EMPLOYEE_REQUEST_OBJECT from "@salesforce/schema/sirenum__Employee_Request__c";
import ALL_DAY_FIELD from "@salesforce/schema/sirenum__Employee_Request__c.sirenum__All_Day__c";
import TYPE_FIELD from "@salesforce/schema/sirenum__Employee_Request__c.sirenum__Type__c";
import START_DATETIME from "@salesforce/schema/sirenum__Employee_Request__c.sirenum__Start_Time__c";
import END_DATETIME from "@salesforce/schema/sirenum__Employee_Request__c.sirenum__End_Time__c";
import CONTACT_FIELD from "@salesforce/schema/sirenum__Employee_Request__c.sirenum__Contact__c";

export default class EmployeeRequestsListView extends LightningModal {
    @api
    contactId;

    @api
    recordId;

    object = EMPLOYEE_REQUEST_OBJECT;
    allDayField = ALL_DAY_FIELD;
    typeField = TYPE_FIELD;
    startDatetimeField = START_DATETIME;
    endDatetimeField = END_DATETIME;
    contactField = CONTACT_FIELD;

    _formReady = false;
    _submitting = false;

    _allDaySelected = false;
    _startDateIso = "";
    _endDateIso = "";

    get isLoading() {
        return this._submitting || !this._formReady;
    }

    get saveDisabled() {
        return !this._formReady || this._submitting;
    }

    get typeDisabled() {
        return !!this.recordId;
    }

    get createUpdateLabel() {
        return this.recordId ? "Update Employee Request" : "Create Employee Request";
    }

    get displayDateTimeFields() {
        return !this._allDaySelected;
    }

    get startDatetime() {
        return this._startDateIso;
    }

    get endDatetime() {
        return this._endDateIso;
    }

    // The start/end date is in ISO GMT onload event and stored as such. The date (date only when AllDay is selected)
    // that's output is a "ISO8601 formatted date string" (i.e. no time component). The base LWC
    // appears to simply drop the time part of the ISO string, which means this can output the wrong date
    // since it's correct to GMT, but not the users TZ. Therefore we offset the date here for the users device TZ.
    get startDate() {
        return this.offsetDateToUsersTimezone(this._startDateIso);
    }

    get endDate() {
        return this.offsetDateToUsersTimezone(this._endDateIso);
    }

    offsetDateToUsersTimezone(isoDateStringToOffset) {
        if (!isoDateStringToOffset) {
            return "";
        }
        const dateToOffset = new Date(isoDateStringToOffset);
        const tzOffset = dateToOffset.getTimezoneOffset() * 60000;
        return new Date(dateToOffset.getTime() - tzOffset).toISOString();
    }

    handleOnLoad(event) {
        this._allDaySelected = this.refs.allDayField.value;
        this._startDateIso = event.detail?.records?.[this.recordId]?.fields?.["sirenum__Start_Time__c"]?.value || "";
        this._endDateIso = event.detail?.records?.[this.recordId]?.fields?.["sirenum__End_Time__c"]?.value || "";
        this._formReady = true;
    }

    handleCreateClick() {
        const fields = [
            ...this.template.querySelectorAll("lightning-input-field"),
            ...this.template.querySelectorAll("lightning-input")
        ];
        let valid = true;

        for (let i = 0; i < fields.length; i++) {
            const field = fields[i];

            const fieldValid = field.reportValidity();

            if (!fieldValid) {
                valid = false;
            }
        }

        if (!valid) return;

        const form = this.template.querySelector("lightning-record-edit-form");
        this._submitting = true;
        form.submit();
    }

    handleCancelClick() {
        this.close();
    }

    handleOnSuccess(event) {
        const newRecordId = event.detail.id;
        this._submitting = false;
        this.close(newRecordId);
    }

    handleOnError() {
        this._submitting = false;
    }

    handleAllDayChange(event) {
        this._allDaySelected = !!event.detail.value;
    }

    handleStartDateChange(event) {
        let startDate = event.detail.value;

        // The time here is arbitary but must be before the end time (so that the dates are inclusive) - if the user is using this they
        // are using the Date input (i.e. "All Day" is selected) and Sirenum will recalculate this regardless
        if (!startDate.includes("T")) {
            startDate += "T09:00:00Z";
        }

        this._startDateIso = startDate;
    }

    handleEndDateChange(event) {
        let endDate = event.detail.value;

        // The time here is arbitary but must be after the start time (so that the dates are inclusive) - if the user is using this they
        // are using the Date input (i.e. "All Day" is selected) and Sirenum will recalculate this regardless
        if (!endDate.includes("T")) {
            endDate += "T17:00:00Z";
        }

        this._endDateIso = endDate;
    }
}