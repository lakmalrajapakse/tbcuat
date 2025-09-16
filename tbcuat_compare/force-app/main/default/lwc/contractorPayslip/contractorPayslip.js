import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import currentUserId from '@salesforce/user/Id';
import getContractorPayslip from '@salesforce/apex/ContractorPayslipController.getContractorPayslip';

export default class ContractorPayslip extends  NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    _payslipUrl;
    _hasIntimeId;


    /**
    * @description Constructor
    **/
    constructor() {
        super();
        this._hasIntimeId = false;
    }

    /**
    * @description Connected Callback Method
    **/
    connectedCallback() {
        if (this.objectApiName === 'User') {
            this.recordId = currentUserId;
        }
    }

    /**
    * @description Wired method to fetch the user information
    **/ 
    @wire(getContractorPayslip, { recordId : '$recordId'}) 
    contractorPayslipUrl({ error, data }) {
        if (data) {
            this._hasIntimeId = true;
            this._payslipUrl = data;
        } else if (error) {
            this.error = error;
        }
        if (this.template.querySelector('lightning-spinner')) {
            this.template.querySelector('lightning-spinner').classList.add('slds-hide');
        }
    }

    /**
    * @description Method to open the payslips
    **/
    handleOpenPayslips() {
        // Navigate to a URL
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: this._payslipUrl
            }
        });
    }
}