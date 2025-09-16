@isTest
public class MobileMessagingIncomingSMSCallbackTest {
    @testSetup
    static void setup() {
        // Create a dummy contact for matching based on phone number
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            MobilePhone = '+1234567890'
        );
        insert testContact;

        // Create a dummy SMSSettings record (or mock the `SMSSettings.getInstance` method if it's customizable)
        TextIUS_Settings__c settings = new TextIUS_Settings__c(
            textus_privatekey__c = 'dummyPrivateKey',
            API_Token__c = 'testapitoken',
            Default_Admin_Id__c = 'idadmin',
            Default_Name__c = 'defaultname',
            Sender_Phone_Number__c = '+123456789' ,
            SMS_Event_Description_Length__c = 255
        );
        insert settings;
    }

    @isTest
    static void testHandleMessage_Success() {
        // Mock the request
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"action":"message.received","message":{"body":"Hello!"},"conversation":{"formattedPhoneNumber":"+123 456 7890","phoneNumber":"+1234567890"}}');
        req.headers.put('X-TextUs-Signature', 'dummySignature');
        RestContext.request = req;

        // Mock the SMSSettings retrieval
        Test.startTest();
       // SMSSettings mockSettings = SMSSettings.getInstance();
        //mockSettings.textUsPrivateKey = 'dummyPrivateKey'; // Same as set in @testSetup
        //Test.setMock(MockSettings.class, mockSettings);

        // Call the method
        String response = MobileMessagingIncomingSMSCallback.handleMessage();
        //Test.stopTest();

        // Verify assertions
        System.assertEquals('Message Recevied', response);

        // Query the SMS message
        List<MobileMessaging_SMS_Message__c> smsMessages = [SELECT Id, Message_Content__c, Status__c, Direction__c FROM MobileMessaging_SMS_Message__c];
        System.assertEquals(1, smsMessages.size());
        System.assertEquals('Hello!', smsMessages[0].Message_Content__c);
        System.assertEquals('Received', smsMessages[0].Status__c);
        System.assertEquals('inbound', smsMessages[0].Direction__c);

        String standardizePhoneNumber = MobileMessagingIncomingSMSCallback.standardizePhoneNumber('4407549899234');
        System.assert(standardizePhoneNumber.contains('+'), true);
    }

    @isTest
    static void testHandleMessage_NonReceivedAction() {
        // Mock the request with a non-received action
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf('{"action":"message.sent","message":{"body":"Hello!"},"conversation":{"formattedPhoneNumber":"+123 456 7890","phoneNumber":"+1234567890"}}');
        req.headers.put('X-TextUs-Signature', 'dummySignature');
        RestContext.request = req;

        // Call the method
        Test.startTest();
        String response = MobileMessagingIncomingSMSCallback.handleMessage();
        Test.stopTest();

        // Verify the response for non-received action
        System.assertEquals('Action is not incoming', response);
    }

}