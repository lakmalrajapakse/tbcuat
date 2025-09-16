import { api, LightningElement } from 'lwc';;

export default class ImageModal extends LightningElement {
    showModal = false;
    imageLink;

    connectedCallback() {
        
    }

    @api
    openModal(imageLink) {
        this.showModal = true;
        this.imageLink = imageLink;
    }

    closeModal() {
        this.showModal = false;
    }}