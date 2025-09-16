import { LightningElement, track, api } from 'lwc';

export default class QueryModal extends LightningElement {
    @track showModal = false;
    query;

    @api openModal(shiftQuery) {
        this.showModal = true;
        this.query = shiftQuery;
    }

    @api closeModal() {
        this.showModal = false;
    }
}