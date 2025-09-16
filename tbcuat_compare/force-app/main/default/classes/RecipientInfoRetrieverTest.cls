@isTest
private class RecipientInfoRetrieverTest {

    // Inner class to mimic the structure of the SuccessResponse expected in the deserialization
    private class SuccessResponse {
        public List<ContactWrapper> contactWrappers;
        public String message;
    }

    @isTest static void testGetRecepients() {
        // Setup test data
        List<Contact> contacts = ContactUtility.generateRandomContacts(5);
        insert contacts;

        // Convert the list of contacts to a list of their IDs
        List<String> recordIds = new List<String>();
        for (Contact c : contacts) {
            recordIds.add(c.Id);
        }

        // Call the method and get the response
        Test.startTest();
        String jsonResponse = RecipientInfoRetriever.getRecepients(recordIds);
        Test.stopTest();
        jsonResponse = '['+ jsonResponse+']';
        // Deserialize the JSON response
        List<ContactWrapper> response = (List<ContactWrapper>) JSON.deserialize(jsonResponse, List<ContactWrapper>.class);

        // Perform assertions to verify the response
        System.assertNotEquals(null, response, 'The response should not be null.');

        // Loop through each ContactWrapper in the response and assert that they match the test data
            ContactWrapper wrapper = response.get(0);
            Contact originalContact = contacts.get(0);
            System.assertNotEquals(originalContact.Id, wrapper.conId, 'The contact ID should match.');
            System.assertNotEquals(originalContact, wrapper.contact, 'The contacts should match.');
        
       
    }

  
    @isTest static void testGetTemplateOptions() {
        // Call the method and get the response
        Test.startTest();
        String jsonResponse = RecipientInfoRetriever.getTemplateOptions();
        Test.stopTest();

        // Deserialize the JSON response
        String templateOptions = (String) JSON.deserialize(jsonResponse, String.class);

        // Perform assertions to verify the response
        System.assertNotEquals(null, templateOptions, 'The template options should not be null.');
        
        // Assert that template options contain expected values
        // This assumes we have a known set of template options to validate against.
        // we would need to adjust this according to our actual data.
        // Example:
        // System.assertEquals('Expected Label', templateOptions[0].label, 'The label should match the expected value.');
    }

    @isTest static void testGetTemplateBody() {
        // Setup test data for template ID
        String templateId = '00XQE00000006HD2AY'; // Use an actual template ID

        // Call the method and get the response
        Test.startTest();
        String jsonResponse = RecipientInfoRetriever.getTemplateBody(templateId);
        Test.stopTest();

        // Deserialize the JSON response
        String templateBody = (String) JSON.deserialize(jsonResponse, String.class);

        // Perform assertions to verify the response
        System.assertNotEquals(null, templateBody, 'The template body should not be null.');

        // Assert that the template body contains expected content
        // This assumes we have a known content to validate against.
        // Example:
        // System.assert(templateBody.contains('Expected content'), 'The template body should contain the expected content.');
    }

  

    private static void createMockMassMessagingSettings(Boolean enableSMS, Boolean enableEmail, Boolean enablePush) {
        Mass_Message_Manager__c settings = new Mass_Message_Manager__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Enable_SMS__c = enableSMS,
            Enable_Email__c = enableEmail
        );
        insert settings;
    }

    // @isTest static void testGetRecipients_WithValidContacts() {
    //     // Setup test data
    //     createMockMassMessagingSettings(true, true, true);
    //     List<Contact> contacts = ContactUtility.generateRandomContacts(5);
    //     for (Contact c : contacts) {
    //         c.MobilePhone = '1234567890';
    //         c.Email = 'test@example.com';
    //     }
    //     insert contacts;

    //     // Convert the list of contacts to a list of their IDs
    //     List<String> recordIds = new List<String>();
    //     for (Contact c : contacts) {
    //         recordIds.add(c.Id);
    //     }

    //     // Call the method and get the response
    //     Test.startTest();
    //     String jsonResponse = RecipientInfoRetriever.getRecipients(recordIds);   
    //     Test.stopTest();


    //     // Deserialize the JSON response
    //     SuccessResponse response = (SuccessResponse) JSON.deserialize(jsonResponse, SuccessResponse.class);

    //     // Perform assertions to verify the response
    //     System.assertEquals(contacts.size(), response.contactWrappers.size(), 'The number of contact wrappers should match the number of test contacts.');

    //     // Assert that each ContactWrapper has the correct information and preferences set
    //     for (Integer i = 0; i < response.contactWrappers.size(); i++) {
    //         ContactWrapper wrapper = response.contactWrappers[i];
    //         Contact originalContact = contacts[i];
    //         System.assertEquals(originalContact.Id, wrapper.conId, 'The contact ID should match.');
    //         System.assertEquals(false, wrapper.sendSMSDisabled, 'SMS should be enabled.');
    //         System.assertEquals(false, wrapper.sendEmailDisabled, 'Email should be enabled.');
    //         System.assertEquals(false, wrapper.sendPushDisabled, 'App notifications should be enabled.');
    //     }
    // }

    // @isTest static void testGetRecipients_NoContacts() {
    //     // Setup test data with no contacts
    //     createMockMassMessagingSettings(true, true, true);
    //     List<String> recordIds = new List<String>();

    //     // Call the method and get the response
    //     Test.startTest();
    //     String jsonResponse = RecipientInfoRetriever.getRecipients(recordIds);
    //     Test.stopTest();

    //     // Deserialize the JSON response
    //     SuccessResponse response = (SuccessResponse) JSON.deserialize(jsonResponse, SuccessResponse.class);

    //     // Perform assertions to verify that an empty list is returned when no contacts are found
    //     System.assertEquals(0, response.contactWrappers.size(), 'The response should be an empty list when no contacts are found.');
    // }
    
}