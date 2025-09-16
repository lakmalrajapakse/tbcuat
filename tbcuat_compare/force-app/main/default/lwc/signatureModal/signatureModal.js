import { api, LightningElement } from 'lwc';
import getShiftSignature from '@salesforce/apex/SIM_TimeApproval.getShiftSignature';
import { showToast } from 'c/toasts';
import { handleException } from 'c/exceptions';

export default class SimModalPopup extends LightningElement {
    showModal = false;
    hasData;
    isLoading;
    signatureLink;

    connectedCallback() {
        
    }

    @api
    openSignature(signatureLink=undefined) {
        this.showModal = true;
        this.isLoading = true;
        console.log(signatureLink);
        this.signatureLink = signatureLink;
        this.hasData = this.signatureLink != undefined;
    }

    closeSignature() {
        this.showModal = false;
    }
}