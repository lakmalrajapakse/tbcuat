import { LightningElement, api } from 'lwc';
import checkDriver from '@salesforce/apex/DAVIS_CheckDrivingLicenseInvoker.checkDriver';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CheckDrivingLicenseButton extends LightningElement {
    @api recordId; // Automatically gets the Contact ID

    connectedCallback(){
        console.log('executing connected callback');
    }

    

    @api invoke () {
        if (!this.recordId) {
            this._showToast('Error', 'No Contact ID found.', 'error');
            return;
        }

        try {
            checkDriver({ cont: { Id: this.recordId } });
            this._showToast('Success', 'Driving License check initiated successfully.', 'success');
        } catch (error) {
            const errorMessage = error.body?.message || 'An unexpected error occurred.';
            this._showToast('Error', errorMessage, 'error');
        }
    }

    _showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}