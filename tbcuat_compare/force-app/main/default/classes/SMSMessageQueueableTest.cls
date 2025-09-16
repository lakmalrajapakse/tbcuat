@isTest
private class SMSMessageQueueableTest {

    // Create test data for SMS_Message_Queue__c
    @TestSetup
    static void setupTestData() {
        List<SMS_Message_Queue__c> queueItems = new List<SMS_Message_Queue__c>();
        // Populate the list with test records
        for (Integer i = 0; i < 5; i++) {
            queueItems.add(new SMS_Message_Queue__c(
                Recipient_Phone_Number__c = '1234567890',
                Message_Content__c = 'Test Message ' + i,
                Status__c = 'Queue',
                Source__c = 'outgoing' // or any other source than 'incoming'
            ));
        }
        insert queueItems;
    }

    @isTest
    static void testSMSMessageQueueable() {
        //  Query for test data
        List<SMS_Message_Queue__c> queueItems = [SELECT Status__c FROM SMS_Message_Queue__c WHERE Status__c = 'Queue'];

        // Act - Enqueue the job
        Test.startTest();
        System.enqueueJob(new SMSMessageQueueable());
        Test.stopTest();

        // Assert - Refresh the queue items from the database and assert their status is 'Processed'
        queueItems = [SELECT Status__c FROM SMS_Message_Queue__c];
        for (SMS_Message_Queue__c item : queueItems) {
            System.assertEquals('Processed', item.Status__c, 'The item status should be updated to Processed');
        }
    }
}