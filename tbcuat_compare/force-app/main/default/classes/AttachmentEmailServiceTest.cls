@isTest
public class AttachmentEmailServiceTest {    

    // Test method for AttachmentEmailService
    static testmethod void testAttachmentEmailService(){
        
        // Create a test Contact record
        Contact cont = new Contact(firstName='john', lastName='smith', Email='test@test.com', HasOptedOutOfEmail=false);
        insert cont; // Insert the Contact record into the database
        
        // Assert Contact is inserted
        System.assertNotEquals(null, cont.Id, 'Contact should be inserted successfully');

        // Create a test Attachment record associated with the Contact
        Attachment attachment = new Attachment();
        attachment.ParentId = cont.Id; // Associate the Attachment with the Contact
        attachment.Name = 'VRT__Resume_Test_Attachment_for_Parent.pdf'; // Test attachment name
        attachment.Body = Blob.valueOf('Test Data'); // Simulated attachment content
        
        insert attachment; // Insert the Attachment record into the database

        // Assert Attachment is inserted
        System.assertNotEquals(null, attachment.Id, 'Attachment should be inserted successfully');
        System.assertEquals(cont.Id, attachment.ParentId, 'Attachment should be linked to the correct Contact');

        // Create a test inbound email object
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.subject = 'Test Contact Email'; // Set the subject of the email
        email.plainTextBody = attachment.Id; // Set the body to contain the Attachment ID
        env.fromAddress = 'test@test.com'; // Set the sender's email address
        
        // Call the method to test
        Test.startTest();
        AttachmentEmailService atm = new AttachmentEmailService();
        Messaging.InboundEmailResult result = atm.handleInboundEmail(email, env); // Pass the test email and envelope to the service
        Test.stopTest();

        // Assertions for email handling
        System.assertNotEquals(null, result, 'InboundEmailResult should not be null');
        System.assertEquals(true, result.success, 'Email processing should be successful');

        // Verify if the email body contains the attachment ID
        System.assertEquals(attachment.Id, email.plainTextBody, 'Email body should contain the correct attachment ID');
    } 
}