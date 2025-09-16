import { LightningElement,  api, wire, track  } from 'lwc';
import { updateRecord, createRecord, getRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PHOTO_ID from '@salesforce/schema/Contact.sirenum__Photo_ID__c';
import manageAttachment from '@salesforce/apex/UserProfilePictureController.manageAttachment';
import getPhotoUrl from '@salesforce/apex/UserProfilePictureController.getPhotoUrl';


export default class UserProfilePicture extends LightningElement {
    @api recordId;

    @track _attachmentUrl ;

    /**
    * @description Connected Callback Method
    **/
    connectedCallback() {
        this.getUserProfilePicture();
    }

    /**
    * @description Method to get contact profile picture
    **/ 
    getUserProfilePicture() {
        getPhotoUrl({ 
            recordId : this.recordId
        }).then(result => {
            console.log('Result is '+result);
            this._attachmentUrl = result;
        })
        .catch(error => {
            console.log(error);
        });
    }

    /**
    * @description Method to handle on file upload
    **/
    handleOnFileUpload(event) {
        this.template.querySelector('lightning-spinner').classList.remove('slds-hide');
        const file = event.target.files[0];
        var reader = new FileReader()
        reader.onload = () => {
            let base64 = reader.result.split(',')[1]
            this.createAttachment(file.name, base64);
        }
        reader.readAsDataURL(file)
    }

    /**
    * @description Method to create attachment
    **/
    createAttachment(fileName, base64Data) {
        manageAttachment({
            'fileName' : fileName,
            'recordId' : this.recordId,
            'base64Data' : base64Data
        }).then(result => {
            this._attachmentUrl = result;
            this.template.querySelector('lightning-spinner').classList.add('slds-hide');
        })
        .catch(error => {
            console.log(error);
            this.error = error;
            this.template.querySelector('lightning-spinner').classList.add('slds-hide');
        });
    }


    /**
    * @description Method to get the accepted formats
    **/
    get acceptedFormats() {
        return ['.jpg','.png','.jpeg'];
    }
}