/**
 * MassMessageManager
 * This Apex class is designed to manage operations associated with mass messaging functionalities.
 * It provides capabilities to enable/disable messaging features such as Email, SMS, and Push notifications,
 * and includes methods to send messages based on the settings configured in the Mass_Message_Manager__c object.
 * The class ensures that message dispatching adheres to the organization's preferences and governance limits.
 *
 * Usage:
 * - To dispatch messages, invoke the corresponding method with the required parameters.
 * - The class methods verify the enabled settings in Mass_Message_Manager__c before initiating message delivery.
 * - Bulk operations leverage asynchronous processing to enhance performance and comply with Salesforce governor limits.
 *
 * Created by: Issam Alameh
 * Role: Technical Consultant
 * Company: 1218 Global
 * Email: issam.alameh@1218global.com
 * LinkedIn: https://www.linkedin.com/in/issam
 * Created on: 
 * Last modified on: 14 Jan 2024 at 11:30:40 am AEST (Melbourne, Australia)
 *
 * Example:
 * MassMessageManager.dispatchMessages(recepientsJSON, 'Hello, World!');
 */

 public with sharing class MassMessageManager {
    private final MessageDispatcher messageDispatcher;
    private final RecipientInfoRetriever recipientInfoRetriever;

    /**
     * Constructor for message dispatcher dependency injection.
     */
    public MassMessageManager(MessageDispatcher messageDispatcher) {
        this.messageDispatcher = messageDispatcher;
    }

    /**
     * Constructor for recipient info retriever dependency injection.
     */
    public MassMessageManager(RecipientInfoRetriever recipientInfoRetriever) {
        this.recipientInfoRetriever = recipientInfoRetriever;
    }

    /**
     * Retrieves recipients based on provided record IDs.
     *
     * @param recordIds List of record IDs to retrieve recipient information for.
     * @return JSON string representing the recipients.
     */
    @AuraEnabled
    public static String getRecepients(List<String> recordIds) {
        return recipientInfoRetriever.getRecepients(recordIds);
    }

    /**
     * Dispatches messages to a list of recipients with the provided content.
     *
     * @param recepientsJSON JSON string containing recipient details.
     * @param messageContent The content of the message to be dispatched.
     * @return A string result of the dispatch operation.
     */
    @AuraEnabled
    public static String dispatchMessages(String recepientsJSON, String messageContent){
        return messageDispatcher.dispatchMessages(recepientsJSON, messageContent);
    }

   

    /**
     * Retrieves available template options for messaging.
     *
     * @return JSON string representing template options available for messaging.
     */
    @AuraEnabled
    public static String getTemplateOptions() {
        return recipientInfoRetriever.getTemplateOptions();
    }

    /**
     * Retrieves the body content of a specified message template by its ID.
     *
     * @param templateId Salesforce ID of the template to retrieve content for.
     * @return A string containing the template body content.
     */
    @AuraEnabled
    public static String getTemplateBody(Id templateId) {
        return recipientInfoRetriever.getTemplateBody(templateId);
    }       
}