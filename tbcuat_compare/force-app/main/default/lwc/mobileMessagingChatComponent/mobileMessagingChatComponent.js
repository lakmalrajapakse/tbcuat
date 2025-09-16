import { LightningElement, api, track, wire } from 'lwc';
import { fetchPastMessages, sendNewMessage } from './mobileMessagingChatComponentService';
import { subscribeToPushTopic, unsubscribeFromPushTopic, registerErrorListener } from './mobileMessagingChatComponentSubscription';
import { processPastMessagesData } from './mobileMessagingChatComponentMessageProcessor';
import { showToast } from './mobileMessagingChatComponentUtils';
import { labels } from './mobileMessagingChatComponentConstants';
import CONTACT_FIRST_NAME_FIELD from '@salesforce/schema/Contact.FirstName';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getSettings from '@salesforce/apex/SettingsProvider.getSettings';

export default class MobileMessagingChatComponent extends LightningElement {
    fetchPastMessages
    @api recordId
    @track newMessageType = 'outbound'
    @track newMessageContent = '';
    @track pastMessagesContent = [];
    @track isLoading = false;
    @track showLoadMoreButton = true;
    @track messageMap = new Map();
    @track pageNumber = 1;
    @track pageSize = 10;
    @track contactInitials = '';
    @track selectedField = '';
    @track greetingValue = 'Regards';
    

    label = labels;
    subscription = null;

    @wire(getRecord, { recordId: '$recordId', fields: [CONTACT_FIRST_NAME_FIELD] })
    contact;

    // Getter to extract the first name from the Contact record
    get firstName() {
        return getFieldValue(this.contact.data, CONTACT_FIRST_NAME_FIELD);
    }
    renderedCallback() {
        this.adjustToTabHeight();
    }

    adjustToTabHeight() {
        // Check if the elements are defined
        if (this.template.host.parentElement && this.template.host.parentElement.clientHeight) {
            const tabHeight = this.template.host.parentElement.clientHeight;
            this.template.host.style.height = `${tabHeight}px`;
        }
    }


    @wire(getSettings)
    wiredSettings({ error, data }) {
        if (data) {
            this.greetingValue = data.Greetings__c;
        } else if (error) {
            this.greetingValue = 'Regards';
        }
    }

    connectedCallback() {
        Promise.all([
            this.loadMessages()
        ])
            .then(() => {
                this.subscription = subscribeToPushTopic.call(this);
                registerErrorListener.call(this);
            })
            .catch(error => {
                console.log(error)
            });
    }

    disconnectedCallback() {
        unsubscribeFromPushTopic.call(this, this.subscription);
    }

    loadMessages() {
        this.isLoading = true;
        this.newMessageContent = '';
        fetchPastMessages({ contactId: this.recordId, pageNumber: this.pageNumber, pageSize: this.pageSize })

            .then(data => {

                processPastMessagesData.call(this, data);
                this.showLoadMoreButton = data.length === this.pageSize;
            })
            .catch(error => {
                showToast.call(this, 'Error retrieving messages: ' + error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleLoadMore() {
        this.pageNumber++;
        this.loadMessages();
    }

    handleInputChange(event) {
        this.newMessageContent = event.target.value;
        this.isSendDisabled = !this.newMessageContent.trim();
    }

    insertFirstName(event) {
        if (this.firstName !== null) {
            this.newMessageContent = this.newMessageContent + this.firstName;
            this.template.querySelector('.slds-text-longform').value = this.newMessageContent;
        }
    }

    insertGreetings(event) {
        this.newMessageContent = this.newMessageContent + this.greetingValue;
        this.template.querySelector('.slds-text-longform').value = this.newMessageContent;
    }
    handleSendMessage() {
        if (this.newMessageContent.trim()) {
            this.isLoading = true;
            sendNewMessage(this.recordId, this.newMessageContent, this.newMessageType)
                .then(() => {
                    showToast.call(this, 'Message sent successfully', 'success');
                    this.loadMessages();
                })
                .catch(error => {
                    showToast.call(this, 'Error sending message: ' + error);
                })
                .finally(() => {
                    this.newMessageContent = '';
                    this.template.querySelector('.slds-text-longform').value = '';
                    this.isLoading = false;
                });
        } else {
            showToast.call(this, 'Cannot send an empty message', 'warning');
        }
    }


}