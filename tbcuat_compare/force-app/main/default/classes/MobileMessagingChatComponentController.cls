/**
 * MobileMessagingChatComponentController
 * This class is designed to interface with Salesforce Lightning components, providing
 * functionalities to handle mobile messaging within a Salesforce environment.
 * It allows users to fetch past messages related to a specific contact and create new messages.
 *
 * Usage:
 * - This controller is utilized by Aura components to interact with SMS message records.
 * - It enables the retrieval of past SMS messages and creation of new messages through user interface actions.
 *
 * Created by: Issam Alameh
 * Role: Technical Consultant
 * Company: 1218 Global
 * Email: issam.alameh@1218global.com
 * LinkedIn: https://www.linkedin.com/in/issam
 * Created on: [Specify Creation Date Here]
 * Last modified on: 14 Jan 2024
 */
public with sharing class MobileMessagingChatComponentController {

    /**
     * Retrieves past messages for a given contact.
     *
     * @param contactId The ID of the contact whose messages are to be retrieved.
     * @return List<MessageWrapper> A list of message wrappers containing message details.
     */
    @AuraEnabled(cacheable=true)
    public static List<MessageWrapper> getPastMessages(Id contactId) {
        // Ensure the contact ID is not null to avoid invalid queries.
        if (contactId == null) {
            throw new AuraHandledException('Contact ID cannot be null.');
        }

        // Query for messages related to the contact, ordered by creation date in descending order.
        List<MobileMessaging_SMS_Message__c> messageList = [
            SELECT Id, Contact__c, Contact__r.Name, 
            Direction__c, Short_Message__c, CreatedDate, Sender_Name__c, Sender__c
            FROM MobileMessaging_SMS_Message__c
            WHERE Contact__c = :contactId
            ORDER BY CreatedDate DESC
        ];

        // Wrap each message in a MessageWrapper for structured response.
        List<MessageWrapper> messages = new List<MessageWrapper>(); 
        for (MobileMessaging_SMS_Message__c msg : messageList) {
            messages.add(new MessageWrapper(msg));
        }
        return messages;
    }

    /**
     * Inner class to structure the message data for the Aura component.
     * This wrapper is used to encapsulate the message details in a format that is easily 
     * consumable by the Aura component, ensuring that only necessary fields are exposed.
     */
    public class MessageWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String senderName;
        @AuraEnabled public String messageContent;
        @AuraEnabled public String direction;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String senderId;

        /**
         * Constructor for MessageWrapper.
         * Initializes a new instance of the MessageWrapper with details from a given message record.
         *
         * @param msg The MobileMessaging_SMS_Message__c instance containing SMS message data.
         */
        public MessageWrapper(MobileMessaging_SMS_Message__c msg) {
            SMSSettings settings = SMSSettings.getInstance();
            this.id = msg.Id;
            this.senderName = (msg.Sender_Name__c != null) ? msg.Sender_Name__c : settings.adminName;
            this.senderId = (msg.Sender__c != null) ? msg.Sender__c : settings.adminId;
            this.messageContent = msg.Short_Message__c;
            this.direction = msg.Direction__c;
            this.createdDate = msg.CreatedDate;


        }
    }

    // ... [We can include other methods like createNewMessage if they exist in any class]
    
    // I have omitted any pagination logic and related comments. If there are other methods
    // like `createNewMessage` that we want included in this class, we can add them below
    // with similar structured documentation and comments.
// ...

/**
 * Creates a new message associated with a given contact.
 *
 * @param contactId The ID of the contact to whom the message will be associated.
 * @param messageBody The content of the message to be sent.
 * @param newMessageType The type of message being created, e.g., 'Outgoing'.
 * @return MessageWrapper A wrapper containing the details of the newly created message.
 */
@AuraEnabled
public static MessageWrapper createNewMessage(Id contactId, String messageBody,String newMessageType) {
    System.debug('Creating new message for contact ID: ' + contactId);
    System.debug('Message body: ' + messageBody);
    System.debug('Message type: ' + newMessageType);
    // Validate input parameters.
    if (contactId == null) {
        throw new AuraHandledException('Contact ID cannot be null.');
    }
    if (String.isEmpty(messageBody)) {
        throw new AuraHandledException('Message body cannot be empty.');
    }
    if (String.isEmpty(newMessageType)) {
        throw new AuraHandledException('Message type cannot be empty.');
    }

    // Create new message record.
    MobileMessaging_SMS_Message__c newMessage = new MobileMessaging_SMS_Message__c(
        Contact__c = contactId,
        Message_Content__c = messageBody,
        Direction__c = newMessageType,
        Status__c = 'queued',
        Source__c = 'Contact',
        Sender__c = UserInfo.getUserId(),
        Sender_Name__c = UserInfo.getName()
    );

    // Perform DML operation to insert the new message record.
    try {
        insert newMessage;
    } catch (DmlException e) {
        // Handle the exception appropriately.
        throw new AuraHandledException('Error creating new message: ' + e.getMessage());
    }

    // Return the details of the newly created message using the MessageWrapper.
    return new MessageWrapper(newMessage);
}

// ... [Rest of the MobileMessagingChatComponentController class]

}