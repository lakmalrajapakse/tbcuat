import { LightningElement, track, api } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { showToast } from 'c/toasts';

export default class QueryModal extends LightningElement {
    @track showModal = false;
    recordId;
    locationId;
    recordToSplit;
    isDisabled = false;

    @api openModal(recordId, recordToSplit) {
        this.showModal = true;
        this.recordId = recordId;
        this.recordToSplit = recordToSplit;
    }

    @api closeModal() {
        if (this.hasCreated) {
            location.reload();
        } else {
            this.showModal = false;
        }
    }

    handleConfirmAndNew() {
        this.isDisabled = true;
        createRecord({
            apiName: "sirenum__Shift__c",
            fields: {
                sirenum__Scheduled_Start_Time__c: this.recordToSplit.sirenum__Scheduled_Start_Time__c,
                sirenum__Scheduled_End_Time__c: this.recordToSplit.sirenum__Scheduled_End_Time__c,
                sirenum__Contact__c: this.recordToSplit.sirenum__Contact__c,
                sirenum__Team__c: this.recordToSplit.sirenum__Team__c,
                sirenum__Site__c: this.recordToSplit.sirenum__Site__c,
                tc9_ext_sirint__Pay_Rate__c: this.recordToSplit.tc9_ext_sirint__Pay_Rate__c,
                tc9_ext_sirint__Invoice_Rate__c: this.recordToSplit.tc9_ext_sirint__Invoice_Rate__c,
                Purchase_Order_Number__c: this.recordToSplit.Purchase_Order_Number__c,
                sirenum__Contract__c: this.recordToSplit.sirenum__Contract__c,
                Is_Split_Shift__c: this.recordToSplit.Is_Split_Shift__c,
                sirenum__Location__c: this.locationId,
                Engagement__c: this.Engagement__c
            }
        }).then(result => {
            showToast(this, 'Shift was split successfully', 'success');
            this.template.querySelector('lightning-input-field[data-id="location"]').value = null;
            this.locationId = null;
        }).catch(error => {
            showToast(this, error.body.message, 'error');
        }).finally(() => {
            this.isDisabled = false;
            this.hasCreated = true;
        });
    }

    handleConfirm() {
        this.isDisabled = true;
        createRecord({
            apiName: "sirenum__Shift__c",
            fields: {
                sirenum__Scheduled_Start_Time__c: this.recordToSplit.sirenum__Scheduled_Start_Time__c,
                sirenum__Scheduled_End_Time__c: this.recordToSplit.sirenum__Scheduled_End_Time__c,
                sirenum__Contact__c: this.recordToSplit.sirenum__Contact__c,
                sirenum__Team__c: this.recordToSplit.sirenum__Team__c,
                sirenum__Site__c: this.recordToSplit.sirenum__Site__c,
                tc9_ext_sirint__Pay_Rate__c: this.recordToSplit.tc9_ext_sirint__Pay_Rate__c,
                tc9_ext_sirint__Invoice_Rate__c: this.recordToSplit.tc9_ext_sirint__Invoice_Rate__c,
                Purchase_Order_Number__c: this.recordToSplit.Purchase_Order_Number__c,
                sirenum__Contract__c: this.recordToSplit.sirenum__Contract__c,
                Is_Split_Shift__c: this.recordToSplit.Is_Split_Shift__c,
                sirenum__Location__c: this.locationId,
                Engagement__c: this.Engagement__c
            }
        }).then(result => {
            showToast(this, 'Shift was split successfully', 'success');
            setTimeout(function(){ location.reload() }, 3000);
        }).catch(error => {
            showToast(this, error.body.message, 'error');
            this.isDisabled = false;
        }).finally(() => {
        });
    }

    handleLocationChange(event) {
        let values = JSON.parse(JSON.stringify(event.detail.value));
        if (!!values && values.length > 0) {
            this.locationId = values[0];
        } else {
            this.locationId = null;
        }
    }
}