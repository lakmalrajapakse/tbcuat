/**
 * SMSMessageTriggerHandler
 * This class handles the logic for processing SMS messages before and after insert operations.
 * It populates message content with the contact's first name and queues messages for sending.
 *
 * Usage:
 * - Intended to be called from trigger events on MobileMessaging_SMS_Message__c object.
 * - beforeInsert method is called before the records are inserted to the database.
 * - afterInsert method is called after the records are inserted to the database.
 *
 * Created by: Issam Alameh
 * Role: Technical Consultant
 * Company: 1218 Global
 * Email: issam.alameh@1218global.com
 * LinkedIn: https://www.linkedin.com/in/issam
 * Creation Date: [Specify Creation Date Here]
 * Last Modified: 14 Jan 2024
 */
public class SMSMessageTriggerHandler {
    // Static map to hold contacts related to the SMS messages
    private static Map<Id, Contact> contactsMap = new Map<Id, Contact>();

    /**
     * beforeInsert
     * Called before new SMS messages are inserted. It replaces placeholder text with actual contact names.
     *
     * @param newMessages List of new MobileMessaging_SMS_Message__c records being inserted.
     */
    public static void beforeInsert(List<MobileMessaging_SMS_Message__c> newMessages) {
        // Collect contact IDs from the new messages
        Set<Id> contactIds = new Set<Id>();
        for (MobileMessaging_SMS_Message__c message : newMessages) {
            if (message.Contact__c != null) {
                contactIds.add(message.Contact__c);
            }
        }
        
        // Query contacts if there are any contact IDs collected
        if (!contactIds.isEmpty()) {
            contactsMap = new Map<Id, Contact>([SELECT Id, FirstName, MobilePhone FROM Contact WHERE Id IN :contactIds]);
        }
        
        // Regex pattern to find <firstname> or <fn> placeholders
        Pattern firstNamePattern = Pattern.compile('(?i)\\<firstname\\>|\\<fn\\>');

        // Replace placeholders with actual first names in message content
        for (MobileMessaging_SMS_Message__c message : newMessages) {
            Contact relatedContact = contactsMap.get(message.Contact__c);
            
            if (relatedContact != null && message.Message_Content__c != null) {
                Matcher firstNameMatcher = firstNamePattern.matcher(message.Message_Content__c);
                String replacement = relatedContact.FirstName != null ? relatedContact.FirstName : '';
                message.Message_Content__c = firstNameMatcher.replaceAll(replacement);
            }

            // Shorten the message content if necessary
            message.Short_Message__c = (message.Message_Content__c != null) 
                ? message.Message_Content__c.substring(0, Math.min(255, message.Message_Content__c.length())) 
                : null;
        }
    }

    /**
     * afterInsert
     * Called after new SMS messages are inserted. It queues messages for sending.
     *
     * @param newMessages List of newly inserted MobileMessaging_SMS_Message__c records.
     */
    public static void afterInsert(List<MobileMessaging_SMS_Message__c> newMessages) {
        List<SMS_Message_Queue__c> queueItems = new List<SMS_Message_Queue__c>();
    
        // Create queue items for each message to be sent
        for (MobileMessaging_SMS_Message__c message : newMessages) {
            Contact recipientContact = contactsMap.get(message.Contact__c);
    
            if (recipientContact != null) {
                SMS_Message_Queue__c queueItem = new SMS_Message_Queue__c(
                    Recipient_Phone_Number__c = recipientContact.MobilePhone,
                    Message_Content__c = message.Message_Content__c,
                    Message_Record_Id__c = message.Id,
                    Source__c = message.Source__c,
                    Status__c = 'Queue',
                    Sender_Name__c = message.Sender_Name__c,
                    Sender__c = message.Sender__c,
                    Contact__c = message.Contact__c
                    );
                queueItems.add(queueItem);
            }
        }
    
        // Insert queue items and enqueue the job for processing
        if (!queueItems.isEmpty()) {
            insert queueItems;
            System.enqueueJob(new SMSMessageQueueable());
        }
    }
}