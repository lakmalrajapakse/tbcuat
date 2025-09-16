// chatMessage.js
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class MobileMessagingChatMessage extends NavigationMixin(LightningElement) {
    @api message; // Assumes 'message' is the object passed with all the message data
    @api isCommunityUser;
    @api sotMessageId;

    connectedCallback() {
        // In this hook, you might want to perform further initialization if necessary.
    }

    // getter function to determine whether the message is inbound
    get isInboundMessage() {
        return this.message.direction === 'inbound';
    }
    get isInbound() {
        return this.message.direction === 'inbound';
    }

    // Formatting Message Date and Time to display in component
    get formattedTimestamp() {
        const dateTime = new Date(this.message.CreatedDate);
        return dateTime.toLocaleString(); // Formats to local date and time
    }

    // Handling different styles for inbound and outbound messages
    get messageCssClass() {
        return this.isInboundMessage ? 'slds-chat-listitem slds-chat-listitem_inbound' : 'slds-chat-listitem slds-chat-listitem_outbound';
    }
    get messageCssContent() {
        return this.isInboundMessage ? 'slds-chat-message__text slds-chat-message__text_inbound' : 'slds-chat-message__text slds-chat-message__text_outbound';
    }
    // Add any additional logic needed for your specific implementation
    // For example, navigating to record view or handling resend action if necessary
}