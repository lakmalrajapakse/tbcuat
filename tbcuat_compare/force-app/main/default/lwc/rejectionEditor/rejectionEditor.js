import { LightningElement, track, api, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import REJECTION_REASON_FIELD from '@salesforce/schema/sirenum__Shift__c.Rejection_Reason__c';

export default class RejectionEditor extends LightningElement {
    @track showModal = false;
    Rejection_Reason__c;
    Rejection_Reason_Other__c;
    shiftId;

    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: REJECTION_REASON_FIELD })
    picklist;

    get options() {
        if (this.picklist) {
            return this.picklist.data.values;
        } else {
            return [];
        }
    }
    

    @api openModal(shiftId, rejectionReason, rejectionReasonOther){
        this.shiftId = shiftId;
        this.Rejection_Reason__c = rejectionReason;
        this.Rejection_Reason_Other__c = rejectionReasonOther;
        this.showModal = true;
    }

    @api closeModal(){
        this.showModal = false;
    }

    handleChange(event) {
        this[event.currentTarget.dataset.fieldName] = event.detail.value;
    }

    reportToParent() {
        const changeEvent = new CustomEvent('update',
            {
                detail: {
                    shiftId: this.shiftId,
                    rejectionReason: this.Rejection_Reason__c,
                    rejectionReasonOther: this.Rejection_Reason_Other__c
                }
            });
        this.dispatchEvent(changeEvent);
        this.showModal = false;
    }

    get isReasonOther() {
        return this.Rejection_Reason__c !== 'Other';
    }
}