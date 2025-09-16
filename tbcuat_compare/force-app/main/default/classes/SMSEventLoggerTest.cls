@isTest
public class SMSEventLoggerTest {

    @testSetup
    static void setupData() {
        // Insert test data for Contact, CustomNotificationType, and TextIUS_Settings__c

        Contact testContact = new Contact(FirstName = 'John', LastName = 'Doe', Phone = '1234567890',email='test332255@emailtest.com');
        insert testContact;

        // Custom Notification Type for SMS Notification
        //CustomNotificationType smsNotificationType = new CustomNotificationType(DeveloperName = 'New_SMS_Received');
       // insert smsNotificationType;



        // Mock settings for TextIUS_Settings__c
  
       
        TextIUS_Settings__c settings = SettingsProvider.getSettings();
        settings.API_Token__c ='SECURITYTOKEN';
        settings.Sender_Phone_Number__c = '075432333';
        settings.API_URL__c = 'APIURL';
        settings.SMS_Event_Description_Length__c = 100;
        settings.Greetings__c = 'Hello test';
        settings.Default_Admin_Id__c = 'admin id';
        settings.Default_Name__c ='ADMIN NAME';
        insert settings;
    }

    @isTest
    static void testLogSMSEventOutbound() {
        // Retrieve test data
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Id notifiedUserId = UserInfo.getUserId();  // Use the running user's Id for test

        // Call the logSMSEvent method for an outbound SMS
        Test.startTest();
        SMSEventLogger.logSMSEvent('outbound', '1234567890', 'Test message body', testContact.Id, notifiedUserId);
        Test.stopTest();

        // Verify that an Event record was created
        Event smsEvent = [SELECT Subject, WhoId, Description FROM Event WHERE WhoId = :testContact.Id LIMIT 1];
        System.assertEquals('SMS outbound to 1234567890', smsEvent.Subject);
        System.assertEquals('Test message body', smsEvent.Description);
        System.assertEquals(testContact.Id, smsEvent.WhoId);
    }

    @isTest
    static void testLogSMSEventInbound() {
        // Retrieve test data
        Contact testContact = [SELECT Id, FirstName, LastName FROM Contact LIMIT 1];
        Id notifiedUserId = UserInfo.getUserId();  // Use the running user's Id for test

        // Call the logSMSEvent method for an inbound SMS
        Test.startTest();
        SMSEventLogger.logSMSEvent('inbound', '1234567890', 'Test message body', testContact.Id, notifiedUserId);
        Test.stopTest();

        // Verify that an Event record was created
        Event smsEvent = [SELECT Subject, WhoId, Description FROM Event WHERE WhoId = :testContact.Id LIMIT 1];
        System.assertEquals('SMS inbound from 1234567890', smsEvent.Subject);
        System.assertEquals('Test message body', smsEvent.Description);
        System.assertEquals(testContact.Id, smsEvent.WhoId);

        // Verify that a CustomNotification was sent
        // Since we cannot query Messaging.CustomNotification, we rely on debug logs
        // Use the logs to check if the notification was sent successfully
       // String debugLog = Test.getMockHttpResponses();
        //System.assert(debugLog.contains('Notification sent'));
    }

}