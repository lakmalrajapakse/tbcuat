import { LightningElement, wire } from 'lwc';
import getBranchDetails from '@salesforce/apex/ConnectPortalFAQBranchDetailsController.getBranchDetails';

export default class ConnectPortalFAQBranchDetails extends LightningElement {
    branchName = '';
    contactName = '';
    contactEmail = '';
    error;

    @wire(getBranchDetails)
    wiredBranchDetails({ error, data }) {
        if (data) {
            this.branchName = data.branchName;
            this.contactName = data.contactName;
            this.contactEmail = data.contactEmail;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.branchName = '';
            this.contactName = '';
        }
    }
}