import { LightningElement, api, track, wire} from 'lwc';

import { showToast } from 'c/toasts';
import { handleException } from 'c/exceptions';
import { debug } from 'c/debug';

import getRecepients from '@salesforce/apex/MassMessageManager.getRecepients';
import getTemplateOptions from '@salesforce/apex/MassMessageManager.getTemplateOptions';
import getTemplateBody from '@salesforce/apex/MassMessageManager.getTemplateBody';
import dispatchMessages from '@salesforce/apex/MassMessageManager.dispatchMessages';
import getSettings from '@salesforce/apex/SettingsProvider.getSettings';

export default class MassMessageManager extends LightningElement {
    @api recordIds;    
    @track isLoading = true;
    @track messageContent = '';
    @track greetingValue;

    @wire(getSettings)
    wiredSettings({ error, data }) {
        if (data) {
            this.greetingValue = data.Greetings__c;
        } else if (error) {
            this.greetingValue = 'Regards';
        }   
    }
    connectedCallback(){
        console.log("LWC connectedCallback called");
        this.loadRecepients();
        this.loadTemplateOptions();
    }
    insertFirstName(event){ 
        this.messageContent = this.messageContent + "<FIRSTNAME>";
        this.template.querySelector('.slds-text-longform').value = this.messageContent;
    }

    insertGreetings(event){ 
        this.messageContent = this.messageContent + this.greetingValue;
        this.template.querySelector('.slds-text-longform').value = this.messageContent;
    }
    handleActive(event) {
        console.log('event.target.value', JSON.stringify(event.target.value));
        if (event.target.value == 'new'){
            
        }else{

        }
    }
    
    @track hasRecepients = false;
    @track recepients = [];
    loadRecepients() {
        debug('Getting Recepients', this.recordIds);
        getRecepients({
            recordIds: this.recordIds
        }).then(results => {
            let response = JSON.parse(results);
            console.log('loadRecepients', response);
            if (response.success) {
                this.hasRecepients = (response.responseObject && response.responseObject.length > 0);
                this.recepients = response.responseObject;
            }else {
                //error - well managed
                console.log('Err:', response.message);
                showToast(this, response.message, 'error');
            }
        }).catch(err => {
            console.log('Unmanaged Error ', JSON.stringify(err));
            handleException(this, err, true);
        }).finally(fin => {
            this.isLoading = false;
        });
    }

    @track loadingTemplates = true;
    @track templateOptions = [];
    loadTemplateOptions() {
        getTemplateOptions({
        }).then(results => {
            let response = JSON.parse(results);

            console.log('loadTemplateOptions', response);
            if (response.success) {
                this.templateOptions = response.responseObject;
            } 
        }).catch(err => {
            console.log('Unmanaged Error ', JSON.stringify(err));
            handleException(this, err, true);
        }).finally(fin => {
            this.loadingTemplates = false;
        });
    }

    @track loadingTemplateBody = false;
    loadTemplateBody(templateId) {
        this.loadingTemplateBody = true;
        getTemplateBody({
            templateId: templateId
        }).then(results => {
            this.loadingTemplateBody = false;
            let response = JSON.parse(results);
            console.log('loadTemplateBody', response);
            if (response.success) {
                this.messageContent = response.message;
            } 
        }).catch(err => {
            console.log('Unmanaged Error ', JSON.stringify(err));
            //error unmanaged - could be a controller exception or javascript exception
            handleException(this, err, true);
        }).finally(fin => {
            this.loadingTemplateBody = false;
        });
    }
    
    @track sendOperationComplete = false;
    sendMessages() {
        if (!this.reportMessageContentValidity()){
            return;
        }
        this.isLoading = true;
        console.log('Sending notification to recepients', JSON.parse(JSON.stringify(this.recepients)));
        dispatchMessages({
            recepientsJSON: JSON.stringify(this.recepients),
            messageContent: this.messageContent
        }).then(results => {
            let response = JSON.parse(results);
            console.log('dispatchMessages', response);
            if (response.success) {
                this.sendOperationComplete = true;
            } else {
                //error - well managed
                console.log('Err:', response.message);
                showToast(this, response.message, 'error');
            }
        }).catch(err => {
            console.log('Unmanaged Error ', JSON.stringify(err));
            //error unmanaged - could be a controller exception or javascript exception
            handleException(this, err, true);
        }).finally(fin => {
            this.isLoading = false;
        });
    }

    reportMessageContentValidity(){
        const messageInputValidity = [...this.template.querySelectorAll('lightning-textarea')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        return messageInputValidity;
    }
    
    /*

    Utilities

    */
   handleFieldChange(event) {
        let conId = event.target.dataset.conid;
        let isCheckbox = event.target.dataset.ischeckbox;
        let fieldName = event.target.dataset.fieldname;
        let fieldValue = event.detail.value;
        if (isCheckbox){
            fieldValue = event.detail.checked ? true : false;
        }
        console.log('fieldName', JSON.stringify(fieldName));
        console.log('fieldValue', JSON.stringify(fieldValue));

        if (fieldName == 'template'){
            this.loadTemplateBody(fieldValue);
        } else if (fieldName == 'content'){
            this.messageContent = fieldValue;
        }else{
            //Recepients Table Edits
            if (!conId || conId.length == 0)
                return;
            
            for (let i = 0; i < this.recepients.length; i++){
                let recepient = this.recepients[i];
                if (recepient.conId == conId){
                    recepient[fieldName] = fieldValue;
                }                
            }
        }
        console.log('Updated this.recepients', JSON.parse(JSON.stringify(this.recepients)));
    }
    markAll(event){
        let context = this;
        let markType = event.target.dataset.type;
        for (let i = 0; i < context.recepients.length; i++) {
            let recepient = context.recepients[i];
            
            if (markType == 'sms' && !recepient.sendSMSDisabled){
                recepient.sendSMS =  !recepient.sendSMS;
            } else if (markType == 'email' && !recepient.sendEmailDisabled){
                recepient.sendEmail = !recepient.sendEmail;
            } else if (markType == 'push' && !recepient.sendPushDisabled){
                recepient.sendPush = !recepient.sendPush;
            }
        }
    }

    close(){
		setTimeout(
			function() {
				window.history.back();
			},
			1000
		);
	}

}