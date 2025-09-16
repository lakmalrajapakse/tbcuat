@isTest
private class MobileMessagingServiceStatusCallbackTest {

    @isTest static void testCaptureStatus() {
        Contact con = new Contact(LastName = 'Test', FirstName = 'Junior', MobilePhone = '5555555555');
        insert con;
        MobileMessaging_SMS_Message__c testMessage = new MobileMessaging_SMS_Message__c();
        testMessage.Message_Response__c = 'Sent';
        testMessage.Status__c = 'Sent';
        testMessage.Source__c = 'Salesforce';
        testMessage.Direction__c = 'outbound';
        testMessage.Message_Content__c = 'Test Message';
        testMessage.Short_Message__c = 'Test Message';
        testMessage.Contact__c = con.id;

        insert testMessage;

        // Set up mock RestRequest and RestResponse
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/MobileMessagingServiceStatusCallback';  // Set the endpoint URL here
        req.httpMethod = 'POST';
        req.addParameter('messageId', testMessage.Id);
        req.addParameter('SmsStatus', 'Delivered');

        RestContext.request = req;
        RestContext.response = res;

        // Act - Call the method to test
        Test.startTest();
        String result = MobileMessagingServiceStatusCallback.captureStatus();
        Test.stopTest();

        // Assert - Verify that the record was updated correctly
        testMessage = [SELECT Message_Response__c FROM MobileMessaging_SMS_Message__c WHERE Id =: testMessage.Id];
        System.assertEquals('Delivered', testMessage.Message_Response__c);
    }
}