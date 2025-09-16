import { LightningElement, track, api } from 'lwc';
import { showToast } from 'c/toasts';
import { debug } from 'c/debug';

import { deleteRecord } from 'lightning/uiRecordApi';

export default class ShiftBreakEditor extends LightningElement {
    @track shiftId;
    @track breakId;
    @track _startTime;
    @track _endTime;
    @track isPaid;

    @track isUpdate = false;
    

    @track showModal = false;
    @api openModal(shiftId, breakId, startTime, endTime, isPaid) {
        debug('ShiftBreakCreator shiftId', shiftId);
        debug('ShiftBreakCreator breakId', breakId);
        this.shiftId = shiftId;
        this.breakId = breakId;
        this.start = startTime;
        this.end = endTime;
        this.isPaid = isPaid;
        this.showModal = true;      
        this.isUpdate = this.breakId ? true : false;
    }

    @api closeModal(){
        this.showModal = false;
    }

    handleOnDelete(){
        this.isLoading = true;
        deleteRecord(this.breakId)
            .then(() => {
                this.reportToParent();
            })
            .catch(error => {
                showToast(this, ('Error deleting break - ' + error.body.message), 'error');
            });
    }

    @track isLoading = true;
    handleOnLoad(event){
        debug('handleOnLoad', event.detail);
        this.isLoading = false;
    }
    handleOnSubmit(){
        this.isLoading = true;
    }

    handleSuccess(event) {
        showToast(this, 'Updates made succesfully', 'success');
        this.breakId = event.detail.id;
        this.reportToParent();
    }

    handleError(event){
        debug('err', event.detail);
        this.isLoading = false;
        showToast(this, (event.detail.message + ' - ' + event.detail.detail), 'error');
    }

    reportToParent() {
        this.isLoading = false;
        this.showModal = false;

        const changeEvent = new CustomEvent('update',
            {
                detail: {
                    shiftId: this.shiftId,
                    breakId: this.breakId
                }
            });
        this.dispatchEvent(changeEvent);
    }    

    get start() {
        return this._startTime;
    }

    set start(value) {
        this._startTime = value;
    }

    get end() {
        return this._endTime;
    }

    set end(value) {
        this._endTime = value;
    }
}