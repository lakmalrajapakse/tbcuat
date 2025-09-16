/**
 * MobileMessagingServiceStatusCallback
 * This class defines a REST endpoint that acts as a callback service for handling status updates of SMS messages.
 * It is exposed as a REST resource and listens for HTTP POST requests with status updates from the SMS service provider.
 *
 * Usage:
 * - The service provider should send an HTTP POST request to this endpoint with the message ID and status as parameters.
 * - The endpoint captures the status and updates the corresponding Salesforce record.
 *
 * Company: 1218 Global
 */
@RestResource(urlMapping='/MobileMessagingServiceStatusCallback/*')
global class MobileMessagingServiceStatusCallback {

    /**
     * Captures the status of an SMS message from an HTTP POST request and updates the Salesforce record.
     * The method retrieves the message ID and status from the request parameters, queries the corresponding record,
     * and updates it with the status received from the SMS service provider.
     *
     * @return A string indicating the result of the operation.
     */
    @HttpPost
    global static String captureStatus() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // Extract message ID and SMS status from request parameters
        String messageId = req.params.get('messageId');
        String smsStatus = req.params.get('SmsStatus');

        // Query Salesforce to find the message record by ID
        List<MobileMessaging_SMS_Message__c> messageList 
              = [SELECT Id, Message_Response__c 
                 FROM MobileMessaging_SMS_Message__c 
                 WHERE Id =: messageId];

        // Check if a record with the given ID exists
        if(!messageList.isEmpty()) {
            // If found, update the message record with the new status
            MobileMessaging_SMS_Message__c message = messageList[0];
            message.Message_Response__c = smsStatus;
            update message;
        } 

        // Return a success response
        return 'Success';
    }
}