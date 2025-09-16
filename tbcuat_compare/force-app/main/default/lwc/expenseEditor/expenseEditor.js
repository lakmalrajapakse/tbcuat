import { LightningElement, api, track } from 'lwc';
import { debug } from 'c/debug';
import { handleException } from 'c/exceptions';
import { showToast } from 'c/toasts';
import Utils from './Utils';

import { NavigationMixin } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';

export default class ExpenseEditor extends NavigationMixin(LightningElement) {
    @api recordId;
    shiftId;
    contactId;
    contractId;
    shiftDate;
    expenseId;

    @track showModal = false;
    @api openModal(shiftId, contactId, contractId, shiftDate, expenseId){
        this.shiftId = shiftId;
        this.contactId = contactId;
        this.contractId = contractId;
        this.shiftDate = shiftDate ? this.formatDate(shiftDate) : shiftDate;
        this.showModal = true;      
        this.recordId = expenseId;
        this.isUpdate = this.expenseId ? true : false;
        this.expenseId = expenseId;
    }

    formatDate(newDate) {
        // returns array for day, month, year
        let dateElements = newDate.split('/');
        let shiftDate = new Date(dateElements[2], dateElements[1] - 1, dateElements[0]);
        shiftDate.setDate(shiftDate.getDate() + 1);
        return shiftDate.toISOString();
    }

    
    handleOnDelete(){
        this.isLoading = true;
        deleteRecord(this.expenseId)
            .then(() => {
                this.showModal = false;
                this.reportToParent();
            })
            .catch(error => {
                showToast(this, ('Error deleting expense - ' + error.body.message), 'error');
            });
    }

    @api closeModal(){
        this.showModal = false;
    }

    handleOnLoad(event){
        debug('handleOnLoad', event.detail);
    }

    @track isLoading = false;    
    handleOnSubmit(event){
        this.isLoading = true;
    }

    handleSuccess(event) {
        showToast(this, 'Updates made succesfully', 'success');
        this.isLoading = false;
        this.reportToParent(event.detail.id);
        this.showModal = false;
    }

    handleError(event){
        debug('err', event.detail);
        this.isLoading = false;
        showToast(this, (event.detail.message + ' - ' + event.detail.detail), 'error');
    }

    reportToParent(recordId) {
        const changeEvent = new CustomEvent('update',
            {
                detail: {
                    recordId: recordId,
                }
            });
        this.dispatchEvent(changeEvent);
    }

    navigateToRecordViewPage() {
        // View a custom object record.
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'sirenum__Expense__c',
                actionName: 'view'
            }
        });
    }
}