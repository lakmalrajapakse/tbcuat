import { api } from "lwc";

import LightningModal from "lightning/modal";
import PAY_QUERY_OBJECT from "@salesforce/schema/Pay_Query__c";
import TYPE_FIELD from "@salesforce/schema/Pay_Query__c.Type__c";
import DESCRIPTION_FIELD from "@salesforce/schema/Pay_Query__c.Description_of_your_Query__c";
import STATUS_FIELD from "@salesforce/schema/Pay_Query__c.Status__c";
import CONTACT_FIELD from "@salesforce/schema/Pay_Query__c.Person__c";
import PAYSLIPDATE_FIELD from "@salesforce/schema/Pay_Query__c.Payslip_Date__c";

export default class PayQueriesListViewNew extends LightningModal {
    @api
    contactId;

    object = PAY_QUERY_OBJECT;
    typeField = TYPE_FIELD;
    descriptionField = DESCRIPTION_FIELD;
    statusField = STATUS_FIELD;
    contactField = CONTACT_FIELD;
    paySlipDateField = PAYSLIPDATE_FIELD;

    _formReady = false;
    _submitting = false;

    get isLoading() {
        return this._submitting || !this._formReady;
    }

    get saveDisabled() {
        return !this._formReady || this._submitting;
    }

    handleOnLoad() {
        this._formReady = true;
    }

    handleCreateClick() {
        const fields = this.template.querySelectorAll("lightning-input-field");
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
}