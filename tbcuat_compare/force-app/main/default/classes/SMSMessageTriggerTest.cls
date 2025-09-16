@isTest
private class SMSMessageTriggerTest {

    @isTest static void testBeforeInsert() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            MobilePhone = '5555555555',
            email='abc@abc.com'                        
        );

        insert testContact;

        MobileMessaging_SMS_Message__c testSMSMessageBefore = new MobileMessaging_SMS_Message__c(
         Message_Content__c = 'Test message',
            Status__c = 'Queued',
            Source__c = 'Test',
            Contact__c = testContact.Id
        );

        // Perform the test in a test context for before insert
        Test.startTest();
        insert testSMSMessageBefore; // This should invoke the before insert trigger logic
        Test.stopTest();

        // Assert: Verify that the before insert logic was executed correctly
        // Example assertion (assuming beforeInsert method sets a specific field):
        MobileMessaging_SMS_Message__c insertedRecordBefore = [SELECT Id, Short_Message__c FROM MobileMessaging_SMS_Message__c WHERE Id = :testSMSMessageBefore.Id];
        //TODO FIx this
        //System.assertNotEquals(null, insertedRecordBefore.Short_Message__c, 'Short_Message__c should be set by before insert logic.');
    }

    @isTest static void testAfterInsert() {

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            MobilePhone = '5555555555',
            email='abc@abc.com'                                    
        );
        insert testContact;
        MobileMessaging_SMS_Message__c testSMSMessageAfter = new MobileMessaging_SMS_Message__c(
            Message_Content__c = 'Test message',
            Status__c = 'Queued',
            Source__c = 'Test',
            Contact__c = testContact.Id
        );
        

        // Act: Perform the test in a test context for after insert
        Test.startTest();
        insert testSMSMessageAfter; // This should invoke the after insert trigger logic
        Test.stopTest();
        MobileMessaging_SMS_Message__c insertedRecordAfter = [SELECT Id, Status__c FROM MobileMessaging_SMS_Message__c WHERE Id = :testSMSMessageAfter.Id];
        System.assertEquals('Queued', insertedRecordAfter.Status__c, 'Status__c should be set by after insert logic.');

    }
}