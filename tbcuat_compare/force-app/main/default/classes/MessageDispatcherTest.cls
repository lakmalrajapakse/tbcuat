@isTest
private class MessageDispatcherTest {

    // Utility method to create a JSON string from a list of ContactWrapper objects
    private static String createRecipientsJSON(List<ContactWrapper> contactWrappers) {
        return JSON.serialize(contactWrappers);
    }

    // Test dispatchMessages with empty message content
    @isTest static void testDispatchMessagesEmptyMessage() {
        String recipientsJSON = createRecipientsJSON(new List<ContactWrapper>{ /* Populate with test data if needed */ });
        String messageContent = '';

        String response = MessageDispatcher.dispatchMessages(recipientsJSON, messageContent);
        Response.ErrorResponse errorResponse = (Response.ErrorResponse) JSON.deserialize(response, Response.ErrorResponse.class);

        System.assertNotEquals(null, errorResponse, 'An error response should be returned for empty message content.');
        System.assertEquals('No Message Content. Please add a message', errorResponse.message, 'The error message should indicate that message content is missing.');
    }

    // Test dispatchMessages with invalid JSON string
    @isTest static void testDispatchMessagesInvalidJSON() {
        String recipientsJSON = 'invalid json';
        String messageContent = 'Hello, World!';

        String response = MessageDispatcher.dispatchMessages(recipientsJSON, messageContent);
        Response.ErrorResponse errorResponse = (Response.ErrorResponse) JSON.deserialize(response, Response.ErrorResponse.class);

        System.assertNotEquals(null, errorResponse, 'An error response should be returned for invalid JSON.');
        // The specific error message may vary depending on the exception caught
    }

    // Test dispatchMessages with no recipients
    @isTest static void testDispatchMessagesNoRecipients() {
        String recipientsJSON = createRecipientsJSON(new List<ContactWrapper>{}); // Empty list
        String messageContent = 'Hello, World!';

        String response = MessageDispatcher.dispatchMessages(recipientsJSON, messageContent);
        Response.ErrorResponse errorResponse = (Response.ErrorResponse) JSON.deserialize(response, Response.ErrorResponse.class);

        System.assertNotEquals(null, errorResponse, 'An error response should be returned when there are no recipients.');
        System.assertEquals('No one selected to send the message to', errorResponse.message, 'The error message should indicate that no recipients are selected.');
    }

    // Test dispatchMessages with valid inputs
    @isTest static void testDispatchMessagesNullRecipients() {
        String recipientsJSON = '';
        String messageContent = 'Hello, World!';
    
        String response = MessageDispatcher.dispatchMessages(recipientsJSON, messageContent);
        Response.ErrorResponse errorResponse = (Response.ErrorResponse) JSON.deserialize(response, Response.ErrorResponse.class);
    
        System.assertNotEquals(null, errorResponse, 'An error response should be returned when recipientsJSON is null.');
        System.assertNotEquals(null, errorResponse.message, 'The error message should indicate that recipientsJSON is null.');
    }
    @isTest static void testDispatchMessagesValidInputs() {
        // Assuming ContactWrapper is a valid class and has a constructor that takes necessary parameters
            List<ContactWrapper> contactWrappers = new List<ContactWrapper>();

            // Define the number of ContactWrapper objects we want to create
            Integer numberOfContactWrappersToCreate = 7; // Change this to our desired number
            
            for (Integer i = 0; i < numberOfContactWrappersToCreate; i++) {
                // Create a Contact record for the ContactWrapper
                Contact contact = new Contact(
                    FirstName = 'FirstName' + i,
                    LastName = 'LastName' + i,
                    Email = 'email' + i + '@example.com',
                    MobilePhone = '(123) 456-789' + i
                );
                
                // Randomly generate Boolean values for sending SMS, Email, and Push
                Boolean sendSMS = Math.random() > 0.5;      // 50% chance of true
                Boolean sendEmail = Math.random() > 0.5;    // 50% chance of true
                Boolean sendPush = Math.random() > 0.5;     // 50% chance of true
            
                // Create a ContactWrapper instance with random values and add it to the list
                ContactWrapper contactWrapper = new ContactWrapper(
                    contact,
                    false, // SMS status (we can set a default value here if needed)
                    false, // Email status (we can set a default value here if needed)
                    false, // Push status (we can set a default value here if needed)
                    sendSMS,
                    sendEmail,
                    sendPush
                );
            
                // Add the ContactWrapper to the list
                contactWrappers.add(contactWrapper);
            }
            
            // Now 'contactWrappers' contains a list of ContactWrapper objects with randomized values
            
        String recipientsJSON = createRecipientsJSON(contactWrappers);
        String messageContent = 'Hello, World!';

        // Since the actual sending is asynchronous and handled by a future method,
        // we don't need to (and cannot) test its execution in this unit test.
        // We can only test that dispatchMessages handles inputs correctly and returns a success response.

        String response = MessageDispatcher.dispatchMessages(recipientsJSON, messageContent);
        Response.SuccessResponse successResponse = (Response.SuccessResponse) JSON.deserialize(response, Response.SuccessResponse.class);

        System.assertNotEquals(null, successResponse, 'A success response should be returned for valid inputs.');
        System.assertEquals('Sending!', successResponse.message, 'The success message should indicate that messages are being sent.');
    }

    // Additional tests can be written to cover more edge cases and scenarios.
}