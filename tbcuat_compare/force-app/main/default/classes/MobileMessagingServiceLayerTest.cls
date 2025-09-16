@isTest
private class MobileMessagingServiceLayerTest {

    // Helper method to create a mock configuration for the messaging service
    private static void createMockMobileMessagingConfig() {
        MobileMessagingConfig__mdt mockConfig = new MobileMessagingConfig__mdt(
            DeveloperName = 'Test_Config',
            Label = 'Test Config',
            Account_SID__c = 'test_sid',
            Auth_Token__c = 'test_token',
            Sender_Phone_Number__c = '+15005550006', // This is a magic number for testing purposes
            Endpoint__c = 'https://test.endpoint.com',
            Site_Domain__c = 'https://test.callback.com',
            IsActive__c = true
        );
    }

    // Method to simulate the response from the external service
    @isTest static void mockHttpResponse() {
        // Create mock configuration data
        createMockMobileMessagingConfig();

        // Set up the mock HTTP response generator
        Test.setMock(HttpCalloutMock.class, new MobileMessagingServiceMock());

        // Call the method to test, which will invoke the mock response
        Test.startTest();
        MobileMessagingServiceLayer.sendSMSAsync('+1234567890', 'Test message', 'a1Sxx0000001gWE', 'a1Sxx0000001gWE'); //added value to make it deploy
        Test.stopTest();

        // Perform assertions or further logic as necessary
        // Note: Since @future methods are executed after Test.stopTest(),
        // any assertions related to the future method's execution should be here.
    }

    // Inner class to implement the HttpCalloutMock interface
    private class MobileMessagingServiceMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setStatusCode(201); // Set as would be expected for a successful API call
            response.setBody('{"success":true,"message":"The SMS has been sent successfully!"}');
            response.setHeader('Content-Type', 'application/json');
            return response;
        }
    }
}