@isTest
private class MessageHandlerTest {

    // Helper method to create a serialized ContactWrapper JSON string
    private static String createSerializedContactWrapper(Boolean sendSMS, Boolean sendEmail, Boolean sendPush) {
        ContactWrapper wrapper = new ContactWrapper();
        // ... Set properties on the wrapper as needed for the test
        wrapper.sendSMS = sendSMS;
        wrapper.sendEmail = sendEmail;
        wrapper.sendPush = sendPush;
        return JSON.serialize(wrapper);
    }

    // Test the queueMessages method with different messaging preferences
    @isTest static void testQueueMessages() {
        // Setup test data
        List<String> serializedContacts = new List<String>{
            createSerializedContactWrapper(true, false, false), // SMS only
            createSerializedContactWrapper(false, true, false), // Email only
            createSerializedContactWrapper(false, false, true), // Push only
            createSerializedContactWrapper(true, false, true) // SMS and Push only
        };

        Test.startTest();
        // Call the method under test
        MessageHandler.queueMessages(serializedContacts);
        Test.stopTest();

        // Asserts to verify correct behavior
        // we would need to verify that the messages are queued correctly,
        // which might involve querying any objects that are used to store queued messages.
        // Additionally, we would need to check that no errors were logged if processing was successful.
    }

    // Test the error handling in queueMessages method
    @isTest static void testQueueMessagesErrorHandling() {
        // Setup test data with an invalid ContactWrapper (e.g., missing required fields)
        List<String> serializedContacts = new List<String>{
            '{"sendSMS":true,"sendEmail":true,"sendPush":true}' // Assuming this is an invalid JSON for ContactWrapper
        };

        Test.startTest();
        // Call the method under test
        MessageHandler.queueMessages(serializedContacts);
        Test.stopTest();

        // Asserts to verify that errors were logged correctly
        // This might involve checking debug logs or any error logging mechanism in place.
    }

    // Additional tests should be written to cover more scenarios,
    // such as partial failures, database rollbacks, etc.
}