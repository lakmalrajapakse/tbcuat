import { track } from 'lwc';
import { formatDate, getInitialsFromName, computeMessageClass } from './mobileMessagingChatComponentUtils';
// Processes and formats past messages data


const processPastMessagesData = function (data) {
    if (data.length > 0) {
        this.hasPastMessages = true;

        this.contactInitials = getInitialsFromName(data[0].senderName);

        const newMessages = data.map(message => {
            const formattedDate = formatDate(message.createdDate);
            return {
                id: message.id,
                ...message,
                formattedTimestamp: formattedDate,
                initials: this.contactInitials,
                messageClass: computeMessageClass(message.direction),
                isOutbound: message.direction === 'outbound',
            };
        });

        // Append new messages to the existing list

        this.pastMessagesContent = [...this.pastMessagesContent, ...newMessages];
    } else {
        // No more messages to load
        this.showLoadMoreButton = false;
    }
};


// Updates the message map with new or updated messages
const updateMessageMap = function (date, sobject) {
    try {

        if (!date || !sobject) {
            return;
        }

        const formattedDate = formatDate(date);

        const initials = this.contactInitials;

        const messageClass = computeMessageClass(sobject.Direction__c);

        const isOutbound = sobject.Direction__c === 'outbound';

        const theDate = date;

        const direction = sobject.Direction__c;

        const messageContent = sobject.Short_Message__c;

        const newMessage = {
            id: sobject.Id,
            createdDate: theDate,
            direction: direction,
            messageContent: messageContent,
            formattedTimestamp: formattedDate,
            initials: initials,
            messageClass: messageClass,
            isOutbound: isOutbound,
            ownerId: sobject.OwnerId
        };
        //this.pastMessagesContent = [newMessage,...this.pastMessagesContent];
        this.pastMessagesContent.unshift(newMessage);
    } catch (error) {
        console.error("Error in updateMessageMap:", error);
    }
};

export { processPastMessagesData, updateMessageMap };