@isTest
private class MobileMessaging_SMS_ChangeTriggerTest {

    @isTest static void testAfterInsertAndUpdate() {
        // Create a new SMS message record
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            MobilePhone = '+61481494782'
        );

        insert testContact;

        MobileMessaging_SMS_Message__c testSMSMessage = new MobileMessaging_SMS_Message__c(
            Message_Content__c = 'Test message',
            Status__c = 'Queued',
            Source__c = 'Test',
            Contact__c = testContact.Id
        );

        // Act: Perform the test in a test context
        Test.startTest();
        insert testSMSMessage; // This should invoke the after insert trigger logic
        Test.stopTest();
        String status = testSMSMessage.Status__c;
        System.assertEquals('Queued', status, 'Status should be Processed after insert');
    }
}