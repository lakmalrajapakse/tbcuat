/**
 * MessageDispatcher
 * This class manages the dispatching of messages to a set of recipients. It is designed to handle
 * the serialization of recipient data and the actual sending process. The messages are dispatched 
 * asynchronously to support bulk operations without impacting user experience or system performance.
 *
 * Usage:
 * - Invoke dispatchMessages() with a JSON string of recipient data and a message content string.
 *
 * Created by: Issam Alameh
 * Role: Technical Consultant
 * Company: 1218 Global
 * Email: issam.alameh@1218global.com
 * LinkedIn: https://www.linkedin.com/in/issam
 * Created on: [Creation Date]
 * Last modified on: 14 Jan 2024 at 7:50:21 pm AEST (Melbourne, Australia)
 */

 public with sharing class MessageDispatcher {

    /**
     * AuraEnabled method that serves as an entry point for sending messages from the Salesforce UI.
     * It validates input parameters, deserializes JSON to ContactWrapper objects, and initiates
     * the asynchronous sending process.
     *
     * @param recepientsJSON  JSON string representing the recipients' information.
     * @param messageContent  The actual content of the message to be sent.
     * @return String         Serialized JSON response indicating the operation result.
     */
    @AuraEnabled
    public static String dispatchMessages(String recepientsJSON, String messageContent) {
        System.debug('receipientJson: ' + recepientsJSON);

        // Validate that message content is not empty
        if (messageContent == null || messageContent.length() == 0) {
            return JSON.serialize(new Response.ErrorResponse('No Message Content. Please add a message'));
        }

        try {
            // Deserialize the JSON string into a list of ContactWrapper objects
            List<ContactWrapper> wrappedContacts = (List<ContactWrapper>) JSON.deserialize(recepientsJSON, List<ContactWrapper>.class);

            // Check if there are any contacts to send messages to
            if (wrappedContacts == null || wrappedContacts.size() == 0) {
                return JSON.serialize(new Response.ErrorResponse('No one selected to send the message to'));
            }

            System.debug('WRAPPED: ' + wrappedContacts);

  
            // Iterate over each ContactWrapper and prepare the message content
            for (ContactWrapper cw : wrappedContacts) {
            //    System.debug('Selected Contacts: ' + cw.contact);
                // Here we might customize the message content per contact if needed
                String templateMessage = messageContent;
                cw.message = templateMessage; // Assign the message content to each wrapper
            }

            // Serialize each ContactWrapper back into JSON after adding the message content
            List<String> serializedContacts = new List<String>();
            for (ContactWrapper cw : wrappedContacts) {
                serializedContacts.add(JSON.serialize(cw));
            }


            // Call the @future method to process the messages asynchronously
            MessageHandler.queueMessages(serializedContacts);

        } catch (Exception e) {
            // Handle any exceptions that occur during processing
            String generalError = e.getMessage() +'. Code: '+ e.getLineNumber();
            // Return a serialized error response with details from the exception
            return JSON.serialize(new Response.ErrorResponse(generalError));
        }

        // If everything goes well, return a success response
        return JSON.serialize(new Response.SuccessResponse('Sending!'));
    }
 


}