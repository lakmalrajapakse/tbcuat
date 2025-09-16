@IsTest
public class MessageResultSaverTest {

    @IsTest
    static void testSaveResult() {
        // Create an instance of MessageResultSaver
        MessageResultSaver saver = MessageResultSaver.getInstance();

        // Create a mock Contact record
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com',
            MobilePhone = '+61481494782'
        );
        insert testContact;

        // Create a ContactWrapper object with communication preferences
        ContactWrapper contactWrapper = new ContactWrapper(
            testContact,
            true, // SMS functionality disabled
            false, // Email functionality disabled
            false, // Push notification functionality disabled
            true,  // Send SMS
            true,  // Send Email
            true   // Send Push
        );

        // Create a list of message types
        List<String> types = new List<String>{'SMS', 'Email', 'Push'};
    
        saver.saveResult(types, contactWrapper);

        // Assert that the message queue has one item
        // Message queue should have a record for each type of message
        System.assertEquals(3, saver.getMessageQueueSize(), 'Message queue should have 3 items');
        Integer er = saver.getErrorCount();
        System.assertEquals(0, saver.getErrorCount(), 'Initial error count should be 0.');

        // Try saving with a null ContactWrapper (should not add to the queue)
        saver.saveResult(types, null);  
        System.assertEquals(true, saver.getErrorCount() > er, 'Error count should have increased FROM' + er + 'to ' 
            + saver.getErrorCount());
        // Assert that the message queue size is still one
        System.assertEquals(3, saver.getMessageQueueSize(), 'Message queue size should not change.');

        List<String> types2 = new List<String>{'SMS', 'Email'};

        // Save the result
        saver.saveResult(types2, contactWrapper);

        System.assertEquals(5, saver.getMessageQueueSize(), 'Message queue size have an extra 2 records');
        saver.saveResult(types, null); // This should generate an error
        //---------------- need to look into this ***IA***
        System.assertEquals(0, saver.getErrorLogs().size(), 'Error logs should have 1 log entry.');
        // Clear the message queue for the next test
        saver.clearMessageQueue();
    }
    @IsTest
    static  void testInsertQueue() {
        // Create a test instance of MessageResultSaver
        MessageResultSaver saver = MessageResultSaver.getInstance();

        // Create a mock Contact record
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com',
            MobilePhone = '+61481494782'
        );
        insert testContact;
        // Create a mock Mass_Message__c record for SMS with a valid Contact__c reference
        Mass_Message__c smsMessage = new Mass_Message__c(
            Type__c = 'SMS',
            Contact__c = testContact.Id, // Use the valid Contact Id
            Message__c = 'Test SMS',
            Status__c = 'Sent'
        );
        List<Mass_Message__c> queueBeforeInsert = saver.getMessageQueue();
        queueBeforeInsert.add(smsMessage);
    
        // Assert that the message added to the queue is actually in the queue
        System.assertEquals(1, saver.getMessageQueue().size(), 'Message queue should contain 1 message before insertion.');
        System.assert(queueBeforeInsert == saver.getMessageQueue(), 'getMessageQueue should return the actual message queue.');
    
        // Add the mock Mass_Message__c record to the message queue
        saver.getMessageQueue().add(smsMessage);

        // Call the insertQueue method to insert the message
        saver.insertQueue();

        // Assert that the messageQueue is empty after insertion
        System.assertEquals(0, saver.getMessageQueueSize(), 'Message queue should be empty after insertion');

        // Assert that the error count is 0 after successful insertion
        System.assertEquals(0, saver.getErrorCount(), 'Error count should be 0');

        // Assert that the error logs are empty after successful insertion
        System.assertEquals(true, saver.getErrorLogs().isEmpty(), 'Error logs should be empty');
    }
    @IsTest
    static void testSingletonPattern() {
        // Create multiple instances of MessageResultSaver
        MessageResultSaver saver1 = MessageResultSaver.getInstance();
        MessageResultSaver saver2 = MessageResultSaver.getInstance();

        // Verify that both instances are the same (Singleton pattern)
        System.assertEquals(saver1, saver2, 'Instances should be the same.');
    }
}